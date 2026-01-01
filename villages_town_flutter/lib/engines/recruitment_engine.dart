import 'dart:ui';
import '../data/models/unit.dart';
import '../data/models/unit_type.dart';
import '../data/models/village.dart';
import 'game_manager.dart';

class RecruitmentEngine {
  (bool can, String reason) canRecruit(UnitType unitType, int quantity, Village village) {
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

    // Check cost
    final stats = unitType.stats;
    final totalCost = stats.cost.map((k, v) => MapEntry(k, v * quantity));
    final game = GameManager.shared;
    if (!game.canAfford(village.owner, totalCost)) {
      return (false, 'Insufficient resources');
    }

    return (true, '');
  }

  List<Unit> recruitUnits(UnitType unitType, int quantity, Village village, Offset coordinates) {
    final (can, _) = canRecruit(unitType, quantity, village);
    if (!can) return [];

    final game = GameManager.shared;
    final stats = unitType.stats;
    final totalCost = stats.cost.map((k, v) => MapEntry(k, v * quantity));

    if (!game.spendResources(village.owner, totalCost)) return [];

    // Reduce population
    village.modifyPopulation(-quantity * 10);
    village.recruitsThisTurn += quantity;

    // Create units
    final units = <Unit>[];
    for (var i = 0; i < quantity; i++) {
      units.add(Unit.create(unitType, village.owner, coordinates));
    }

    // Add to army at village
    final armiesAtVillage = game.getArmiesAt(village.id);
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

    return units;
  }
}
