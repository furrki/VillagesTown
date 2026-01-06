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
      final distance = GeoCoordinate.distanceKm(armyCoordinates, target.coordinates);
      final isNeutral = target.owner == 'neutral';

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

      // Score calculation (only for viable targets)
      double score = 0;

      // 1. Distance penalty (prefer closer targets)
      score -= (distance / 50.0);

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

      if (score > highScore) {
        highScore = score;
        best = target;
      }
    }

    // Require minimum score to attack
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
