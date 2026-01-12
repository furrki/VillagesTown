import 'dart:math';
import '../../core/types/typed_ids.dart';
import '../entities/army.dart';
import '../entities/game_state.dart';
import '../entities/unit.dart';
import '../entities/village.dart';

/// Result of combat resolution.
class CombatResult {
  final List<BattleRound> rounds;
  final bool attackerWon;
  final int finalAttackerCount;
  final int finalDefenderCount;
  final int attackerCasualties;
  final int defenderCasualties;
  final int garrisonCasualties;

  const CombatResult({
    required this.rounds,
    required this.attackerWon,
    required this.finalAttackerCount,
    required this.finalDefenderCount,
    required this.attackerCasualties,
    required this.defenderCasualties,
    required this.garrisonCasualties,
  });
}

/// Pure combat resolution service.
/// All methods are stateless - they compute results without side effects.
class CombatService {
  final Random _random;

  CombatService([Random? random]) : _random = random ?? Random();

  /// Resolve combat between attackers and defenders.
  /// Returns a CombatResult without modifying any state.
  CombatResult resolveCombat({
    required List<Unit> attackers,
    required List<Unit> defenders,
    required int garrisonStrength,
    bool defenderHasBonus = false,
  }) {
    final rounds = <BattleRound>[];
    int attackerCount = attackers.length;
    int defenderCount = defenders.length + garrisonStrength;
    final initialAttackers = attackerCount;
    final initialDefenders = defenders.length;
    final initialGarrison = garrisonStrength;

    // Calculate type advantage
    final hasAdvantage = _checkTypeAdvantage(attackers, defenders);

    while (attackerCount > 0 && defenderCount > 0) {
      final round = _resolveRound(
        attackerCount: attackerCount,
        defenderCount: defenderCount,
        attackerBonus: hasAdvantage ? 1 : 0,
        defenderBonus: defenderHasBonus ? 1 : 0,
      );
      rounds.add(round);
      attackerCount -= round.attackerLosses;
      defenderCount -= round.defenderLosses;
    }

    final attackerCasualties = initialAttackers - attackerCount.clamp(0, initialAttackers);
    final totalDefenderLost = (initialDefenders + initialGarrison) - defenderCount.clamp(0, initialDefenders + initialGarrison);

    // Distribute defender losses between army units and garrison
    final defenderCasualties = totalDefenderLost.clamp(0, initialDefenders);
    final garrisonCasualties = (totalDefenderLost - defenderCasualties).clamp(0, initialGarrison);

    return CombatResult(
      rounds: rounds,
      attackerWon: attackerCount > 0,
      finalAttackerCount: attackerCount.clamp(0, initialAttackers),
      finalDefenderCount: defenderCount.clamp(0, initialDefenders + initialGarrison),
      attackerCasualties: attackerCasualties,
      defenderCasualties: defenderCasualties,
      garrisonCasualties: garrisonCasualties,
    );
  }

  /// Resolve a single round of combat (dice rolling).
  BattleRound _resolveRound({
    required int attackerCount,
    required int defenderCount,
    required int attackerBonus,
    required int defenderBonus,
  }) {
    // Attacker can roll up to 3 dice, defender up to 2
    final attDiceCount = min(attackerCount, 3);
    final defDiceCount = min(defenderCount, 2);

    // Roll dice
    var attRolls = List.generate(attDiceCount, (_) => _random.nextInt(6) + 1)
      ..sort((a, b) => b.compareTo(a)); // Descending
    var defRolls = List.generate(defDiceCount, (_) => _random.nextInt(6) + 1)
      ..sort((a, b) => b.compareTo(a)); // Descending

    // Apply bonuses to highest roll
    final originalAttRolls = List<int>.from(attRolls);
    final originalDefRolls = List<int>.from(defRolls);

    if (attRolls.isNotEmpty && attackerBonus > 0) {
      attRolls[0] += attackerBonus;
    }
    if (defRolls.isNotEmpty && defenderBonus > 0) {
      defRolls[0] += defenderBonus;
    }

    // Compare dice
    int attLosses = 0;
    int defLosses = 0;
    final comparisons = min(attRolls.length, defRolls.length);

    for (var i = 0; i < comparisons; i++) {
      if (attRolls[i] > defRolls[i]) {
        defLosses++;
      } else {
        // Ties go to defender
        attLosses++;
      }
    }

    // Generate narration
    final narration = _generateNarration(
      attackerRolls: originalAttRolls,
      defenderRolls: originalDefRolls,
      attackerLosses: attLosses,
      defenderLosses: defLosses,
    );

    return BattleRound(
      attackerRolls: originalAttRolls,
      defenderRolls: originalDefRolls,
      attackerBonus: attackerBonus,
      defenderBonus: defenderBonus,
      attackerLosses: attLosses,
      defenderLosses: defLosses,
      narration: narration,
    );
  }

  /// Check if attackers have type advantage over defenders.
  bool _checkTypeAdvantage(List<Unit> attackers, List<Unit> defenders) {
    if (attackers.isEmpty || defenders.isEmpty) return false;

    // Calculate average damage multiplier
    double totalMultiplier = 0;
    int comparisons = 0;

    for (final attacker in attackers) {
      for (final defender in defenders) {
        totalMultiplier += attacker.unitType.damageMultiplier(defender.unitType);
        comparisons++;
      }
    }

    if (comparisons == 0) return false;
    final avgMultiplier = totalMultiplier / comparisons;

    // Grant bonus if 20%+ advantage on average
    return avgMultiplier >= 1.2;
  }

  /// Generate battle narration for a round.
  String _generateNarration({
    required List<int> attackerRolls,
    required List<int> defenderRolls,
    required int attackerLosses,
    required int defenderLosses,
  }) {
    final attTotal = attackerRolls.fold(0, (a, b) => a + b);
    final defTotal = defenderRolls.fold(0, (a, b) => a + b);

    if (defenderLosses > attackerLosses) {
      if (defenderLosses >= 2) {
        return 'A devastating assault breaks through!';
      }
      return 'The attackers push forward.';
    } else if (attackerLosses > defenderLosses) {
      if (attackerLosses >= 2) {
        return 'The defenders hold firm against the onslaught!';
      }
      return 'The defenders repel the attack.';
    } else {
      if (attTotal > defTotal) {
        return 'A fierce exchange favoring the attackers.';
      }
      return 'A brutal stalemate ensues.';
    }
  }

  /// Calculate army strength for comparison.
  int calculateStrength(Army army) {
    return army.totalAttack + army.totalDefense + (army.totalHP ~/ 10);
  }

  /// Calculate total defender strength including garrison.
  int calculateDefenseStrength(List<Army> defenderArmies, int garrison) {
    var strength = garrison * 15; // Garrison is strong defensive force
    for (final army in defenderArmies) {
      strength += calculateStrength(army);
    }
    return strength;
  }

  /// Estimate win probability for AI decision making.
  double estimateWinProbability({
    required int attackerStrength,
    required int defenderStrength,
  }) {
    if (defenderStrength == 0) return 1.0;
    final ratio = attackerStrength / defenderStrength;
    // Sigmoid-like function
    return ratio / (1 + ratio);
  }

  /// Create a battle record from combat result.
  BattleRecord createBattleRecord({
    required Army attacker,
    required Village location,
    required List<Army> defenders,
    required CombatResult result,
  }) {
    final defenderOwner = location.owner;
    final defenderName = defenders.isNotEmpty
        ? defenders.first.name
        : 'Garrison';

    return BattleRecord(
      id: BattleId.generate(),
      attackerName: attacker.name,
      defenderName: defenderName,
      attackerId: attacker.owner,
      defenderId: defenderOwner,
      originVillageId: attacker.origin,
      locationName: location.name,
      rounds: result.rounds,
      attackerWon: result.attackerWon,
      initialAttackerCount: attacker.unitCount,
      initialDefenderCount: defenders.fold(0, (sum, a) => sum + a.unitCount),
      initialGarrisonCount: location.garrisonStrength,
      timestamp: DateTime.now(),
      isPending: true,
    );
  }
}
