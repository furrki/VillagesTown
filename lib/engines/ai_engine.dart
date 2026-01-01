import 'dart:math';
import 'dart:ui';
import '../data/map/game_map.dart';
import '../data/models/ai_personality.dart';
import '../data/models/building.dart';
import '../data/models/player.dart';
import '../data/models/resource.dart';
import '../data/models/unit_type.dart';
import '../data/models/village.dart';
import 'building_construction_engine.dart';
import 'game_manager.dart';
import 'recruitment_engine.dart';

class AIEngine {
  final BuildingConstructionEngine _buildingEngine = BuildingConstructionEngine();
  final RecruitmentEngine _recruitmentEngine = RecruitmentEngine();

  void executeAITurn(Player player, GameMap map) {
    if (player.isHuman) return;

    var villages = map.villages.where((v) => v.owner == player.id).toList();
    if (villages.isEmpty) return;

    // 1. Economic Phase
    for (final village in villages) {
      _makeEconomicDecisions(player, village);
    }

    // 2. Military Phase
    villages = map.villages.where((v) => v.owner == player.id).toList();
    for (final village in villages) {
      _makeMilitaryDecisions(player, village, map);
    }

    // 3. Combat Phase
    _executeCombatStrategy(player, map);
  }

  void _makeEconomicDecisions(Player player, Village village) {
    if (!village.canBuildMore) return;

    final personality = player.aiPersonality ?? AIPersonality.balanced;

    List<Building> buildingPriorities;
    switch (personality) {
      case AIPersonality.aggressive:
        buildingPriorities = [
          Building.barracks,
          Building.ironMine,
          Building.market,
          Building.archeryRange,
          Building.farm,
        ];
      case AIPersonality.economic:
        buildingPriorities = [
          Building.farm,
          Building.market,
          Building.lumberMill,
          Building.barracks,
          Building.granary,
          Building.temple,
          Building.ironMine,
        ];
      case AIPersonality.balanced:
        buildingPriorities = [
          Building.barracks,
          Building.farm,
          Building.market,
          Building.ironMine,
          Building.lumberMill,
          Building.archeryRange,
        ];
    }

    for (final building in buildingPriorities) {
      if (village.buildings.any((b) => b.name == building.name)) continue;

      final (can, _) = _buildingEngine.canBuild(building, village);
      if (can) {
        _buildingEngine.buildBuilding(building, village);
        GameManager.shared.updateVillage(village);
        break;
      }
    }
  }

  void _makeMilitaryDecisions(Player player, Village village, GameMap map) {
    final personality = player.aiPersonality ?? AIPersonality.balanced;
    final globalResources = GameManager.shared.getGlobalResources(player.id);

    final availableUnits = _recruitmentEngine.getAvailableUnits(village);
    if (availableUnits.isEmpty) return;

    final int goldThreshold;
    final int recruitCount;

    switch (personality) {
      case AIPersonality.aggressive:
        goldThreshold = 50;
        recruitCount = 3;
      case AIPersonality.economic:
        goldThreshold = 200;
        recruitCount = 1;
      case AIPersonality.balanced:
        goldThreshold = 100;
        recruitCount = 2;
    }

    if ((globalResources[Resource.gold] ?? 0) <= goldThreshold) return;

    final unitPriorities = [UnitType.militia, UnitType.swordsman, UnitType.archer, UnitType.spearman];

    for (final unitType in unitPriorities) {
      if (availableUnits.contains(unitType)) {
        final (can, _) = _recruitmentEngine.canRecruit(unitType, recruitCount, village);
        if (can) {
          _recruitmentEngine.recruitUnits(unitType, recruitCount, village, village.coordinates);
          break;
        }
      }
    }
  }

  void _executeCombatStrategy(Player player, GameMap map) {
    final personality = player.aiPersonality ?? AIPersonality.balanced;
    final game = GameManager.shared;

    final int gracePeriod;
    switch (personality) {
      case AIPersonality.aggressive:
        gracePeriod = 5;
      case AIPersonality.economic:
        gracePeriod = 10;
      case AIPersonality.balanced:
        gracePeriod = 7;
    }

    if (game.currentTurn < gracePeriod) return;

    final stationedArmies = game.getStationedArmiesFor(player.id);
    if (stationedArmies.isEmpty) return;

    final enemies = map.villages.where((v) => v.owner != player.id).toList();
    if (enemies.isEmpty) return;

    for (final army in stationedArmies) {
      final stationedAtId = army.stationedAt;
      if (stationedAtId == null) continue;

      final stationedAt = map.villages.cast<Village?>().firstWhere(
            (v) => v!.id == stationedAtId,
            orElse: () => null,
          );
      if (stationedAt == null) continue;

      // Find best target
      Village? bestTarget;
      var bestTargetScore = -1 << 30;

      for (final enemy in enemies) {
        final defenderArmies = game.getArmiesAt(enemy.id).where((a) => a.owner == enemy.owner);
        final defenderArmyStrength = defenderArmies.fold(0, (sum, a) => sum + a.strength);
        final garrisonStrength = enemy.garrisonStrength * 3;
        final totalDefenderStrength = defenderArmyStrength + garrisonStrength;

        final distance = _calculateDistance(stationedAt.coordinates, enemy.coordinates);
        final advantage = army.strength - totalDefenderStrength;
        var score = advantage - (distance * 5);

        // Bonus for neutral villages
        if (enemy.owner == 'neutral') score += 50;

        if (score > bestTargetScore) {
          bestTargetScore = score;
          bestTarget = enemy;
        }
      }

      if (bestTarget == null) continue;

      final defenderArmies = game.getArmiesAt(bestTarget.id).where((a) => a.owner == bestTarget!.owner);
      final defenderArmyStrength = defenderArmies.fold(0, (sum, a) => sum + a.strength);
      final totalDefenderStrength = defenderArmyStrength + bestTarget.garrisonStrength * 3;

      final bool shouldAttack;
      switch (personality) {
        case AIPersonality.aggressive:
          shouldAttack = army.strength > 0 && army.strength > totalDefenderStrength * 0.8;
        case AIPersonality.economic:
          shouldAttack = army.strength > 0 && army.strength > totalDefenderStrength * 1.5;
        case AIPersonality.balanced:
          shouldAttack = army.strength > 0 && army.strength >= totalDefenderStrength;
      }

      final int minArmySize;
      switch (personality) {
        case AIPersonality.aggressive:
          minArmySize = 3;
        case AIPersonality.economic:
          minArmySize = 5;
        case AIPersonality.balanced:
          minArmySize = 4;
      }

      final isUndefendedNeutral =
          bestTarget.owner == 'neutral' && defenderArmyStrength == 0 && bestTarget.garrisonStrength < 5;

      if ((shouldAttack && army.unitCount >= minArmySize) || (isUndefendedNeutral && army.unitCount >= 2)) {
        game.sendArmy(army.id, bestTarget.id);
      }
    }
  }

  int _calculateDistance(Offset from, Offset to) {
    final dx = (to.dx - from.dx).abs().toInt();
    final dy = (to.dy - from.dy).abs().toInt();
    return max(dx, dy);
  }
}
