import 'dart:math';
import '../data/models/army.dart';
import '../data/models/resource.dart';
import '../data/models/victory_condition.dart';
import '../data/models/village_level.dart';
import '../data/models/village_trait.dart';
import 'game_manager.dart';

class VictoryEngine {
  /// Check if a player has achieved any victory condition.
  /// Returns the achieved VictoryType, or null.
  static VictoryType? checkVictory(GameManager game, String playerId) {
    for (final type in VictoryType.values) {
      final progress = getProgressFor(game, playerId, type);
      if (progress.achieved) return type;
    }
    return null;
  }

  /// Get progress for all victory conditions.
  static List<VictoryProgress> getAllProgress(GameManager game, String playerId) {
    return VictoryType.values
        .map((type) => getProgressFor(game, playerId, type))
        .toList();
  }

  /// Get progress for a specific victory condition.
  static VictoryProgress getProgressFor(
      GameManager game, String playerId, VictoryType type) {
    return switch (type) {
      VictoryType.domination => _checkDomination(game, playerId),
      VictoryType.economic => _checkEconomic(game, playerId),
      VictoryType.military => _checkMilitary(game, playerId),
      VictoryType.imperial => _checkImperial(game, playerId),
    };
  }

  // --- Domination: Control 70% of all villages ---
  static VictoryProgress _checkDomination(GameManager game, String playerId) {
    final totalVillages = game.map.villages.length;
    final owned = game.getPlayerVillages(playerId).length;
    final threshold = (totalVillages * 0.7).ceil();
    final progress = totalVillages > 0 ? (owned / threshold).clamp(0.0, 1.0) : 0.0;

    return VictoryProgress(
      type: VictoryType.domination,
      progress: progress,
      description: '$owned / $threshold villages',
      achieved: owned >= threshold,
    );
  }

  // --- Economic: 10,000 gold + 3 Trade Crossroads villages ---
  static VictoryProgress _checkEconomic(GameManager game, String playerId) {
    const goldTarget = 10000;
    const crossroadsTarget = 3;

    final gold = game.getGlobalResources(playerId)[Resource.gold] ?? 0;
    final crossroads = game.getPlayerVillages(playerId)
        .where((v) => v.trait == VillageTrait.tradeCrossroads)
        .length;

    final goldProgress = (gold / goldTarget).clamp(0.0, 1.0);
    final crossroadsProgress =
        (crossroads / crossroadsTarget).clamp(0.0, 1.0);
    final progress = (goldProgress * 0.5 + crossroadsProgress * 0.5);

    return VictoryProgress(
      type: VictoryType.economic,
      progress: progress,
      description: '${gold.clamp(0, goldTarget)}/$goldTarget gold, $crossroads/$crossroadsTarget trade hubs',
      achieved: gold >= goldTarget && crossroads >= crossroadsTarget,
    );
  }

  // --- Military: 15 battles won + strongest army ---
  static VictoryProgress _checkMilitary(GameManager game, String playerId) {
    const battlesTarget = 15;
    final battlesWon = game.battlesWon[playerId] ?? 0;

    // Check if player has the strongest single army
    final playerArmies = game.getArmiesFor(playerId);
    final playerBestStrength = playerArmies.isEmpty
        ? 0
        : playerArmies
            .map((a) => _armyStrength(a))
            .reduce((a, b) => max(a, b));

    bool hasStrongest = playerBestStrength > 0;
    for (final army in game.armies) {
      if (army.owner == playerId) continue;
      if (_armyStrength(army) >= playerBestStrength) {
        hasStrongest = false;
        break;
      }
    }

    final battlesProgress =
        (battlesWon / battlesTarget).clamp(0.0, 1.0);
    final strengthProgress = hasStrongest ? 1.0 : 0.5;
    final progress = battlesProgress * 0.7 + strengthProgress * 0.3;

    final strengthStr = hasStrongest ? 'strongest' : 'not strongest';
    return VictoryProgress(
      type: VictoryType.military,
      progress: progress,
      description: '$battlesWon/$battlesTarget battles, $strengthStr army',
      achieved: battlesWon >= battlesTarget && hasStrongest,
    );
  }

  // --- Imperial: 5 villages at City level ---
  static VictoryProgress _checkImperial(GameManager game, String playerId) {
    const target = 5;
    final cities = game.getPlayerVillages(playerId)
        .where((v) => v.level == VillageLevel.city)
        .length;
    final progress = (cities / target).clamp(0.0, 1.0);

    return VictoryProgress(
      type: VictoryType.imperial,
      progress: progress,
      description: '$cities / $target cities',
      achieved: cities >= target,
    );
  }

  static int _armyStrength(Army army) {
    int strength = 0;
    for (final unit in army.units) {
      strength += unit.attack + unit.defense + (unit.maxHP ~/ 10);
    }
    return strength;
  }

  /// Calculate end-of-game score.
  static GameScore calculateScore(GameManager game) {
    const playerId = 'player';
    final villages = game.getPlayerVillages(playerId);
    final battlesWon = game.battlesWon[playerId] ?? 0;
    final totalPop = villages.fold<int>(0, (sum, v) => sum + v.population);
    final gold = game.getGlobalResources(playerId)[Resource.gold] ?? 0;

    final selectedType = game.selectedVictoryType;
    final achievedType = checkVictory(game, playerId);

    // Victory type bonus: full bonus if won by selected type, half otherwise
    int victoryBonus = 0;
    if (achievedType != null) {
      if (selectedType == achievedType) {
        victoryBonus = achievedType.scoreBonus;
      } else {
        victoryBonus = achievedType.scoreBonus ~/ 2;
      }
    }

    return GameScore(
      villageScore: villages.length * 100,
      battleScore: battlesWon * 50,
      populationScore: (totalPop * 0.1).round(),
      goldScore: (gold * 0.05).round(),
      speedBonus: max(0, (60 - game.currentTurn) * 10),
      victoryTypeBonus: victoryBonus,
    );
  }
}
