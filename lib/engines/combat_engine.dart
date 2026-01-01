import 'dart:math';
import '../data/map/game_map.dart';
import '../data/models/unit.dart';
import '../data/models/village.dart';

class CombatResult {
  final bool attackerWon;
  final int attackerCasualties;
  final int defenderCasualties;
  final int damage;
  final int experienceGained;

  CombatResult({
    required this.attackerWon,
    required this.attackerCasualties,
    required this.defenderCasualties,
    required this.damage,
    required this.experienceGained,
  });
}

class CombatEngine {
  final Random _random = Random();

  CombatResult resolveCombat({
    required List<Unit> attackers,
    required List<Unit> defenders,
    required GameMap map,
    Village? defendingVillage,
  }) {
    if (attackers.isEmpty) {
      return CombatResult(
        attackerWon: false,
        attackerCasualties: 0,
        defenderCasualties: 0,
        damage: 0,
        experienceGained: 0,
      );
    }

    // Calculate attacker strength with counter bonuses
    var attackerStrength = 0.0;
    for (final attacker in attackers) {
      var unitStrength = attacker.attack.toDouble();
      // Apply counter bonuses
      if (defenders.isNotEmpty) {
        final avgMultiplier = defenders
            .map((d) => attacker.unitType.damageMultiplier(d.unitType))
            .reduce((a, b) => a + b) / defenders.length;
        unitStrength *= avgMultiplier;
      }
      attackerStrength += unitStrength;
    }

    // Calculate defender strength
    var defenderStrength = 0.0;
    for (final defender in defenders) {
      defenderStrength += defender.defense.toDouble();
    }

    // Add garrison strength if defending a village
    if (defendingVillage != null) {
      // Garrison provides defense: (population/10) * level bonus * building bonuses
      var garrisonBonus = (defendingVillage.population / 10) * (1 + defendingVillage.defenseBonus);
      garrisonBonus += defendingVillage.garrisonStrength * 3;

      // Minimum garrison for empty villages
      if (defenderStrength == 0) {
        garrisonBonus = max(garrisonBonus, 10);
      }

      defenderStrength += garrisonBonus;
    }

    // Add some randomness
    attackerStrength *= 0.9 + _random.nextDouble() * 0.2;
    defenderStrength *= 0.9 + _random.nextDouble() * 0.2;

    // Determine winner
    final attackerWon = attackerStrength > defenderStrength;

    // Calculate casualties
    final attackerCasualties = _calculateCasualties(
      attackers,
      defenderStrength / max(attackerStrength, 1),
      attackerWon ? 0.3 : 0.7,
    );

    final defenderCasualties = _calculateCasualties(
      defenders,
      attackerStrength / max(defenderStrength, 1),
      attackerWon ? 0.7 : 0.3,
    );

    // Apply damage
    _applyDamage(attackers, attackerCasualties);
    _applyDamage(defenders, defenderCasualties);

    // Experience gain
    final experienceGained = (defenderStrength / 10).round();

    return CombatResult(
      attackerWon: attackerWon,
      attackerCasualties: attackerCasualties,
      defenderCasualties: defenderCasualties,
      damage: defenderStrength.round(),
      experienceGained: experienceGained,
    );
  }

  int _calculateCasualties(List<Unit> units, double damageRatio, double baseCasualtyRate) {
    if (units.isEmpty) return 0;
    final casualties = (units.length * baseCasualtyRate * damageRatio).round();
    return min(casualties, units.length);
  }

  void _applyDamage(List<Unit> units, int casualties) {
    // Distribute damage among units
    for (var i = 0; i < min(casualties, units.length); i++) {
      units[i].takeDamage(units[i].maxHP); // Kill the unit
    }

    // Apply partial damage to survivors
    for (var i = casualties; i < units.length; i++) {
      final damage = _random.nextInt(units[i].maxHP ~/ 3);
      units[i].takeDamage(damage);
    }
  }
}
