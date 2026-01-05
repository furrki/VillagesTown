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
      int defenderStr = target.garrisonStrength * 3;
      final enemyArmies = game.getArmiesAt(target.id).where((a) => a.owner == target.owner);
      for (final ea in enemyArmies) defenderStr += ea.strength;

      // Score Calculation
      double score = 0;

      // 1. Distance Penalty
      score -= (distance / 50.0);

      // 2. Win Probability Reward
      final advantage = army.strength - defenderStr;
      if (advantage > 0) {
        score += advantage * 0.5;
      } else {
        score -= 1000;
      }

      // 3. Strategic Value Reward
      if (isNeutral) {
         score += 50 * personality.expansionBias;
      } else {
         score += 100 * personality.aggressionBias;
      }

      if (score > highScore) {
        highScore = score;
        best = target;
      }
    }

    if (highScore < 10) return null;

    return best;
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
}
