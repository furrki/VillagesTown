import '../data/map/game_map.dart';
import '../data/models/battle_tactics.dart';
import '../data/models/battle_terrain.dart';
import '../data/models/combat_log.dart';
import '../data/models/village.dart';
import '../data/models/village_level.dart';
import '../data/models/village_trait.dart';
import '../data/models/player.dart';
import '../data/models/army.dart';
import '../data/models/geo_coordinate.dart';
import '../data/models/resource.dart';
import '../data/models/unit_type.dart';
import '../data/models/ai_personality.dart';
import '../data/models/game_modifier.dart';
import '../data/models/victory_condition.dart';
import 'event_engine.dart';
import 'game_manager.dart';

class AIStrategyManager {
  void manageStrategy(Player player, GameMap map, {VictoryType? victoryGoal, VictoryType? playerThreat}) {
    final game = GameManager.shared;
    final personality = player.aiPersonality ?? AIPersonality.balanced;

    // 1. Identify Idle Armies
    final armies = game.getStationedArmiesFor(player.id);
    if (armies.isEmpty) return;

    // 2. Scan Targets (AI has 500km base vision, only attacks visible/discovered)
    final baseVision = 500.0;
    final aiVisionRange = game.activeModifiers.contains(GameModifier.fogEternal)
        ? baseVision * 0.5
        : game.activeModifiers.contains(GameModifier.openBook)
            ? 99999.0
            : baseVision;
    final playerVillages = game.getPlayerVillages(player.id);
    final enemies = map.villages.where((v) {
      if (v.owner == player.id) return false;
      // Check if within AI vision range from any owned village
      for (final pv in playerVillages) {
        final dist = GeoCoordinate.distanceKm(pv.coordinates, v.coordinates);
        if (dist <= aiVisionRange) return true;
      }
      return false;
    }).toList();
    if (enemies.isEmpty) return;

    // 3. Command Each Army
    final playerFood = game.getGlobalResources(player.id)[Resource.food] ?? 100;
    for (final army in armies) {
      final bestTarget = _findBestTarget(
        army, enemies, personality, game,
        playerFood: playerFood,
        victoryGoal: victoryGoal,
        playerThreat: playerThreat,
      );

      if (bestTarget != null) {
         _issueOrder(game, army, bestTarget);
      }
    }
  }

  Village? _findBestTarget(
    Army army, List<Village> potentialTargets, AIPersonality personality, GameManager game,
    {int playerFood = 100, VictoryType? victoryGoal, VictoryType? playerThreat}) {
    Village? best;
    double highScore = -double.infinity;

    final armyCoordinates = _getArmyCoordinates(army, game);
    if (armyCoordinates == null) return null;

    for (final target in potentialTargets) {
      final distance = GeoCoordinate.distanceKm(armyCoordinates, target.coordinates);
      final isNeutral = target.owner == 'neutral';

      // Respect non-aggression pacts (Royal Marriage event)
      if (!isNeutral && EventEngine.hasNonAggressionPact(game, army.owner, target.owner)) {
        continue;
      }

      // Calculate defender strength (garrison + stationed armies)
      int defenderStr = target.garrisonStrength * 2; // Garrison fights at 2x (defensive bonus)
      final enemyArmies = game.getArmiesAt(target.id).where((a) => a.owner == target.owner);
      for (final ea in enemyArmies) {
        defenderStr += ea.strength;
      }

      // Ensure minimum defender strength for calculation
      if (defenderStr < 1) defenderStr = 1;

      // Calculate strength ratio (attacker / defender)
      final strengthRatio = army.strength / defenderStr;

      // Minimum ratio required to attack based on personality
      // Aggressive: needs 1.2x strength, Defensive: needs 2.0x strength
      final minRatioRequired = isNeutral
          ? 1.0 + (1.0 - personality.expansionBias) * 0.5   // 1.0 to 1.5
          : 1.2 + (1.0 - personality.aggressionBias) * 0.8; // 1.2 to 2.0

      // Skip targets where we don't have enough advantage
      if (strengthRatio < minRatioRequired) {
        continue;
      }

      // Skip 4+ turn marches unless target is very weak
      final estimatedTurns = (distance / 80.0).ceil();
      if (estimatedTurns >= 4 && strengthRatio < 2.0) {
        continue;
      }

      // Score calculation (only for viable targets)
      double score = 0;

      // 1. Distance penalty (prefer closer targets, steeper penalty for multi-turn)
      score -= (distance / 30.0);

      // 2. Strength advantage bonus (scaled by how much stronger we are)
      // Ratio of 1.5 = +25 points, 2.0 = +50 points, etc.
      score += (strengthRatio - 1.0) * 50;

      // 3. Strategic value (personality influence)
      if (isNeutral) {
        score += 20 * personality.expansionBias;
      } else {
        score += 30 * personality.aggressionBias;
      }

      // 4. Weak target bonus (easier to take)
      if (defenderStr < army.strength * 0.5) {
        score += 15; // Easy target bonus
      }

      // 5. Trait value bonus: prioritize fertile villages when food-starved
      if (target.trait == VillageTrait.fertile && playerFood < 50) {
        score += 25; // Desperately need food
      }
      if (target.trait == VillageTrait.tradeCrossroads) {
        score += 10; // Trade hubs are always valuable
      }

      // 6. Victory goal: prioritize targets that help AI's victory path
      if (victoryGoal != null) {
        score += _victoryGoalBonus(victoryGoal, target);
      }

      // 7. Counter player threat: prioritize attacking player assets
      if (playerThreat != null && target.owner == 'player') {
        score += _counterThreatBonus(playerThreat, target);
      }

      if (score > highScore) {
        highScore = score;
        best = target;
      }
    }

    // Require minimum score to attack
    if (highScore < 10) return null;

    return best;
  }

  /// Bonus score for targets that help the AI pursue its victory goal.
  double _victoryGoalBonus(VictoryType goal, Village target) {
    return switch (goal) {
      // Domination: prioritize any enemy village
      VictoryType.domination => 10.0,
      // Economic: prioritize trade crossroads
      VictoryType.economic => target.trait == VillageTrait.tradeCrossroads ? 30.0 : 0.0,
      // Military: prioritize targets to get battle wins (weaker = easier win)
      VictoryType.military => 15.0,
      // Imperial: avoid attacking, but if forced, prefer high-level villages
      VictoryType.imperial => target.level == VillageLevel.city ? 25.0 : 10.0,
    };
  }

  /// Bonus score for targets that counter the human player's victory path.
  double _counterThreatBonus(VictoryType threat, Village target) {
    return switch (threat) {
      // Player close to domination: attack their villages to reduce control
      VictoryType.domination => 25.0,
      // Player close to economic: attack their trade crossroads and rich villages
      VictoryType.economic => target.trait == VillageTrait.tradeCrossroads ? 40.0 : 15.0,
      // Player close to military: turtle up (negative bonus to discourage attacking)
      VictoryType.military => -20.0,
      // Player close to imperial: attack their cities
      VictoryType.imperial => target.level == VillageLevel.city ? 40.0 : 10.0,
    };
  }

  GeoCoordinate? _getArmyCoordinates(Army army, GameManager game) {
    if (army.stationedAt != null) {
      return game.map.villages.cast<Village?>().firstWhere((v) => v!.id == army.stationedAt, orElse: () => null)?.coordinates;
    }
    return null;
  }

  void _issueOrder(GameManager game, Army army, Village target) {
    game.sendArmy(army.id, target.id);
  }

  /// AI selects terrain based on army composition and personality.
  static BattleTerrain selectTerrain(Army army, AIPersonality personality) {
    final cavalryCount = army.units.where((u) => u.unitType.category == 'Cavalry').length;
    final rangedCount = army.units.where((u) => u.unitType.category == 'Ranged').length;
    final total = army.units.length;

    // Cavalry-heavy → Open Field
    if (total > 0 && cavalryCount / total > 0.4) return BattleTerrain.openField;
    // Archer-heavy → Hill
    if (total > 0 && rangedCount / total > 0.4) return BattleTerrain.hill;
    // Defensive personality → Hill or River Crossing
    if (personality == AIPersonality.defensive) return BattleTerrain.hill;
    // Aggressive → Open Field
    if (personality == AIPersonality.aggressive) return BattleTerrain.openField;
    // Default
    return BattleTerrain.openField;
  }

  /// AI creates battle tactics based on army composition and personality.
  static BattleTactics createTactics(Army army, AIPersonality personality, {bool isDefender = false}) {
    // Engagement order: AI never picks feigned retreat (too risky)
    final order = switch (personality) {
      AIPersonality.aggressive => EngagementOrder.aggressivePush,
      AIPersonality.defensive => EngagementOrder.holdGround,
      AIPersonality.economic => EngagementOrder.holdGround,
      AIPersonality.balanced => EngagementOrder.aggressivePush,
    };

    // Formation: personality-based
    final formation = switch (personality) {
      AIPersonality.aggressive => BattleFormation.crescent,
      AIPersonality.defensive => BattleFormation.shieldWall,
      AIPersonality.economic => BattleFormation.shieldWall,
      AIPersonality.balanced => BattleFormation.shieldWall,
    };

    // Role assignments: aggressive = heavy vanguard, defensive = strong reserve
    final roles = <UnitType, UnitRole>{};
    for (final unit in army.units) {
      final type = unit.unitType;
      if (roles.containsKey(type)) continue;

      if (personality == AIPersonality.aggressive) {
        // Aggressive: cavalry flankers, infantry vanguard
        roles[type] = type.category == 'Cavalry' ? UnitRole.flankers : UnitRole.vanguard;
      } else if (personality == AIPersonality.defensive) {
        // Defensive: ranged reserve, cavalry flankers, infantry main body
        roles[type] = switch (type.category) {
          'Ranged' => UnitRole.reserve,
          'Cavalry' => UnitRole.flankers,
          _ => UnitRole.mainBody,
        };
      } else {
        // Balanced: adaptive
        roles[type] = UnitRole.mainBody;
      }
    }

    return BattleTactics(
      terrain: isDefender ? selectTerrain(army, personality) : null,
      formation: formation,
      engagementOrder: order,
      roleAssignments: roles,
    );
  }
}
