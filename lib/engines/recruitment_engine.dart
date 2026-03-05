import '../data/models/game_modifier.dart';
import '../data/models/geo_coordinate.dart';
import '../data/models/resource.dart';
import '../data/models/unit.dart';
import '../data/models/unit_type.dart';
import '../data/models/village.dart';
import 'game_manager.dart';

class RecruitmentEngine {
  static const _peasantUnits = {UnitType.militia, UnitType.spearman};

  (bool can, String reason) canRecruit(UnitType unitType, int quantity, Village village) {
    final game = GameManager.shared;

    // Peasant War: only militia and spearmen
    if (game.activeModifiers.contains(GameModifier.peasantWar) && !_peasantUnits.contains(unitType)) {
      return (false, 'Only militia and spearmen (Peasant War)');
    }

    // Check mobilization cap
    if (village.recruitsThisTurn + quantity > village.maxRecruitsPerTurn) {
      return (false, 'Mobilization cap reached');
    }

    // Check required building
    final requiredBuilding = getRequiredBuilding(unitType);
    if (requiredBuilding != null && !village.buildings.any((b) => b.name == requiredBuilding)) {
      return (false, 'Requires $requiredBuilding');
    }

    // Check population
    if (village.population < quantity * 10) {
      return (false, 'Insufficient population');
    }

    // Check cost (with Gold Standard modifier)
    final stats = unitType.stats;
    var totalCost = stats.cost.map((k, v) => MapEntry(k, v * quantity));
    if (game.activeModifiers.contains(GameModifier.goldStandard)) {
      totalCost = Map.from(totalCost);
      if (totalCost.containsKey(Resource.gold)) {
        totalCost[Resource.gold] = totalCost[Resource.gold]! * 2;
      }
    }
    if (!game.canAfford(village.owner, totalCost)) {
      return (false, 'Insufficient resources');
    }

    return (true, '');
  }

  List<Unit> recruitUnits(UnitType unitType, int quantity, Village village, GeoCoordinate coordinates) {
    final (can, _) = canRecruit(unitType, quantity, village);
    if (!can) return [];

    final game = GameManager.shared;
    final stats = unitType.stats;
    var totalCost = stats.cost.map((k, v) => MapEntry(k, v * quantity));
    if (game.activeModifiers.contains(GameModifier.goldStandard)) {
      totalCost = Map.from(totalCost);
      if (totalCost.containsKey(Resource.gold)) {
        totalCost[Resource.gold] = totalCost[Resource.gold]! * 2;
      }
    }

    if (!game.spendResources(village.owner, totalCost)) return [];

    // Reduce population
    village.modifyPopulation(-quantity * 10);
    village.recruitsThisTurn += quantity;

    // Get building levels for unit bonuses
    final barracks = village.buildings.where((b) => b.name == 'Barracks').toList();
    final archeryRange = village.buildings.where((b) => b.name == 'Archery Range').toList();
    final stables = village.buildings.where((b) => b.name == 'Stables').toList();

    final barracksLevel = barracks.isNotEmpty ? barracks.first.level : 0;
    final archeryRangeLevel = archeryRange.isNotEmpty ? archeryRange.first.level : 0;
    final stablesLevel = stables.isNotEmpty ? stables.first.level : 0;

    // Military hub bonus: +15% attack and defense on recruited units
    final isMilitaryHub = village.specialization == VillageSpecialization.militaryHub;

    // Create units with building bonuses
    final units = <Unit>[];
    for (var i = 0; i < quantity; i++) {
      final unit = Unit.create(
        unitType,
        village.owner,
        coordinates,
        barracksLevel: barracksLevel,
        archeryRangeLevel: archeryRangeLevel,
        stablesLevel: stablesLevel,
      );
      if (isMilitaryHub) {
        unit.bonusAttack += (unitType.stats.attack * 0.15).round();
        unit.bonusDefense += (unitType.stats.defense * 0.15).round();
      }
      units.add(unit);
    }

    // Add to army at village (owned by same player!)
    final armiesAtVillage = game.getArmiesAt(village.id)
        .where((a) => a.owner == village.owner)
        .toList();
    if (armiesAtVillage.isNotEmpty) {
      final army = armiesAtVillage.first;
      army.addUnits(units);
      game.updateArmy(army);
    } else {
      game.createArmy(units, village.id, village.owner);
    }

    game.updateVillage(village);
    return units;
  }

  String? getRequiredBuilding(UnitType unitType) {
    return switch (unitType) {
      UnitType.militia || UnitType.spearman || UnitType.swordsman => 'Barracks',
      UnitType.archer || UnitType.crossbowman => 'Archery Range',
      UnitType.lightCavalry || UnitType.knight => 'Stables',
    };
  }

  List<UnitType> getAvailableUnits(Village village) {
    final game = GameManager.shared;
    final units = <UnitType>[];
    final hasBarracks = village.buildings.any((b) => b.name == 'Barracks');
    final hasArchery = village.buildings.any((b) => b.name == 'Archery Range');
    final hasStables = village.buildings.any((b) => b.name == 'Stables');

    if (hasBarracks) {
      units.addAll([UnitType.militia, UnitType.spearman, UnitType.swordsman]);
    }
    if (hasArchery) {
      units.addAll([UnitType.archer, UnitType.crossbowman]);
    }
    if (hasStables) {
      units.addAll([UnitType.lightCavalry, UnitType.knight]);
    }

    // Peasant War: filter to only militia and spearmen
    if (game.activeModifiers.contains(GameModifier.peasantWar)) {
      units.removeWhere((u) => !_peasantUnits.contains(u));
    }

    return units;
  }
}
