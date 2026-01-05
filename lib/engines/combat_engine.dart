import 'dart:math';
import '../data/map/game_map.dart';
import '../data/models/unit.dart';
import '../data/models/village.dart';
import '../data/models/combat_log.dart';

class CombatEngine {
  final Random _random = Random();

  BattleRecord resolveCombat({
    required String attackerName,
    required String defenderName,
    required String attackerId,
    required String defenderId,
    String? originVillageId,
    required List<Unit> attackers,
    required List<Unit> defenders,
    required GameMap map,
    Village? defendingVillage,
    int garrisonCount = 0,
  }) {
    final rounds = <BattleRound>[];
    final initialAttackerCount = attackers.length;
    final initialDefenderCount = defenders.length;
    
    // Virtual stacks for calculation
    int attackerCount = initialAttackerCount;
    int defenderCount = initialDefenderCount;
    
    // Calculate Bonuses once
    bool hasDefenseBonus = defendingVillage != null;
    bool attackerTypeAdvantage = _checkAdvantage(attackers, defenders);
    bool defenderTypeAdvantage = _checkAdvantage(defenders, attackers);

    // Combat Loop - Simulation only
    while (attackerCount > 0 && defenderCount > 0) {
      // 1. Determine Dice Count
      final attDiceCount = min(attackerCount, 3);
      final defDiceCount = min(defenderCount, 2);

      // 2. Roll Dice
      List<int> attRolls = List.generate(attDiceCount, (_) => _random.nextInt(6) + 1)..sort((a, b) => b.compareTo(a));
      List<int> defRolls = List.generate(defDiceCount, (_) => _random.nextInt(6) + 1)..sort((a, b) => b.compareTo(a));

      // 3. Apply Bonuses
      int attBonusApplied = 0;
      int defBonusApplied = 0;

      if (attackerTypeAdvantage && attRolls.isNotEmpty) {
        attRolls[0] += 1;
        attBonusApplied = 1;
      }

      if (defRolls.isNotEmpty) {
        if (hasDefenseBonus) {
          defRolls[0] += 1;
          defBonusApplied += 1;
        }
        if (defenderTypeAdvantage) {
          defRolls[0] += 1;
          defBonusApplied += 1;
        }
      }
      
      // 4. Compare Dice
      int roundAttLosses = 0;
      int roundDefLosses = 0;
      final comparisons = min(attRolls.length, defRolls.length);

      for (var i = 0; i < comparisons; i++) {
        if (attRolls[i] > defRolls[i]) {
          roundDefLosses++;
        } else {
          roundAttLosses++;
        }
      }

      attackerCount -= roundAttLosses;
      defenderCount -= roundDefLosses;

      rounds.add(BattleRound(
        attackerRolls: List.from(attRolls),
        defenderRolls: List.from(defRolls),
        attackerBonus: attBonusApplied,
        defenderBonus: defBonusApplied,
        attackerLosses: roundAttLosses,
        defenderLosses: roundDefLosses,
        narration: 'Exchange of fire',
      ));
    }

    // NOTE: We do NOT apply casualties here anymore. 
    // This engine is now pure simulation for the plan.

    return BattleRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      attackerName: attackerName,
      defenderName: defenderName,
      attackerId: attackerId,
      defenderId: defenderId,
      originVillageId: originVillageId,
      locationName: defendingVillage?.name ?? 'Open Field',
      rounds: rounds,
      attackerWon: attackerCount > 0,
      initialAttackerCount: initialAttackerCount,
      initialDefenderCount: initialDefenderCount,
      initialGarrisonCount: garrisonCount,
    );
  }

  bool _checkAdvantage(List<Unit> sideA, List<Unit> sideB) {
    if (sideA.isEmpty || sideB.isEmpty) return false;
    // Simple heuristic: If >50% of sideA strongly counters >50% of sideB
    // For now, simpler: do ANY units have counter?
    // Let's use the average multiplier.
    double totalMult = 0;
    int checks = 0;
    
    // Sample a few matchups to avoid N^2
    final sampleA = sideA.take(5);
    final sampleB = sideB.take(5);
    
    for (var uA in sampleA) {
      for (var uB in sampleB) {
        totalMult += uA.unitType.damageMultiplier(uB.unitType);
        checks++;
      }
    }
    
    if (checks == 0) return false;
    return (totalMult / checks) >= 1.2; // 20% advantage threshold
  }
}
