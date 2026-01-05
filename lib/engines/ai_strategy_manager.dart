import 'dart:math';
import '../data/map/game_map.dart';
import '../data/models/village.dart';
import '../data/models/player.dart';
import '../data/models/army.dart';
import '../data/models/geo_coordinate.dart';
import '../data/models/ai_personality.dart';
import 'game_manager.dart';

class AIStrategyManager {
  
  void manageStrategy(Player player, GameMap map) {
    final game = GameManager.shared;
    final personality = player.aiPersonality ?? AIPersonality.balanced;

    // 1. Identify Idle Armies
    final armies = game.getStationedArmiesFor(player.id);
    if (armies.isEmpty) return;

    // 2. Scan Targets
    final enemies = map.villages.where((v) => v.owner != player.id).toList();
    if (enemies.isEmpty) return;

    // 3. Command Each Army
    for (final army in armies) {
      if (army.hasMovedThisTurn) continue; // Hypothetical property, or just assume one order per turn
      
      // Determine Mission: ATTACK vs DEFEND vs IDLE
      // If our capital is threatened, recall?
      
      final bestTarget = _findBestTarget(army, enemies, personality, game);
      
      if (bestTarget != null) {
         _issueOrder(game, army, bestTarget);
      }
    }
  }

  Village? _findBestTarget(Army army, List<Village> potentialTargets, AIPersonality personality, GameManager game) {
    Village? best;
    double highScore = -double.infinity;
    
    final armyCoordinates = _getArmyCoordinates(army, game);
    if (armyCoordinates == null) return null;

    for (final target in potentialTargets) {
      // Factors
      final distance = GeoCoordinate.distanceKm(armyCoordinates, target.coordinates);
      final isNeutral = target.owner == 'neutral';
      
      // Assess Strength
      int defenderStr = target.garrisonStrength * 3; // Est strength per garrison unit
      // Add stationed enemy armies
      final enemyArmies = game.getArmiesAt(target.id).where((a) => a.owner == target.owner);
      for (final ea in enemyArmies) defenderStr += ea.strength;

      // Score Calculation
      double score = 0;
      
      // 1. Distance Penalty (Don't cross the world)
      score -= (distance / 50.0); 

      // 2. Win Probability Reward
      final advantage = army.strength - defenderStr;
      if (advantage > 0) {
        score += advantage * 0.5; // Reward safe wins
      } else {
        score -= 1000; // Avoid suicide (unless desperate)
      }

      // 3. Strategic Value Reward
      if (isNeutral) {
         score += 50 * personality.expansionBias; // Neutrals are easy expansion
      } else {
         score += 100 * personality.aggressionBias; // Enemy players are high value
      }
      
      // 4. Threshold
      // Must be at least somewhat strictly positive or viable
      if (score > highScore) {
        highScore = score;
        best = target;
      }
    }
    
    // Minimum confidence check
    if (highScore < 10) return null; // Stay home if no good targets

    return best;
  }

  GeoCoordinate? _getArmyCoordinates(Army army, GameManager game) {
    if (army.stationedAt != null) {
      return game.map.villages.cast<Village?>().firstWhere((v) => v!.id == army.stationedAt, orElse: () => null)?.coordinates;
    }
    return null; // Marching armies handled differently?
  }

  void _issueOrder(GameManager game, Army army, Village target) {
    // Basic move order
    game.sendArmy(army.id, target.id);
  }

}
