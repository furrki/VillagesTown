import '../../domain/entities/unit.dart';
import 'battle_terrain.dart';

/// Combat phase types for the three-phase battle system.
enum CombatPhase {
  ranged('Ranged Volley'),
  cavalry('Cavalry Charge'),
  melee('Melee Clash');

  final String displayName;
  const CombatPhase(this.displayName);
}

/// Result of a single combat phase.
class PhaseResult {
  final CombatPhase phase;
  final int attackerLuckRoll; // 1-100
  final int defenderLuckRoll; // 1-100
  final double attackerLuckModifier; // 0.85-1.15
  final double defenderLuckModifier; // 0.85-1.15
  final int attackerKills;
  final int defenderKills;
  final Map<UnitCategory, int> attackerCasualtiesByType;
  final Map<UnitCategory, int> defenderCasualtiesByType;
  final String narration;

  PhaseResult({
    required this.phase,
    required this.attackerLuckRoll,
    required this.defenderLuckRoll,
    required this.attackerLuckModifier,
    required this.defenderLuckModifier,
    required this.attackerKills,
    required this.defenderKills,
    required this.attackerCasualtiesByType,
    required this.defenderCasualtiesByType,
    required this.narration,
  });
}

/// Legacy battle round (kept for compatibility).
class BattleRound {
  final List<int> attackerRolls;
  final List<int> defenderRolls;
  final int attackerBonus;
  final int defenderBonus;
  final int attackerLosses;
  final int defenderLosses;
  final String narration;

  BattleRound({
    required this.attackerRolls,
    required this.defenderRolls,
    this.attackerBonus = 0,
    this.defenderBonus = 0,
    required this.attackerLosses,
    required this.defenderLosses,
    required this.narration,
  });
}

/// Formation types for tactical combat (Phase 2).
/// Rock-Paper-Scissors: ShieldWall > Crescent > Skirmish > ShieldWall
enum BattleFormation {
  shieldWall('Shield Wall', 'Tight defensive infantry line'),
  crescent('Crescent', 'Cavalry-forward encirclement'),
  skirmish('Skirmish', 'Loose spread, mobile harassment');

  final String displayName;
  final String description;
  const BattleFormation(this.displayName, this.description);

  /// Returns the formation this one beats.
  BattleFormation get beats => switch (this) {
        BattleFormation.shieldWall => BattleFormation.crescent,
        BattleFormation.crescent => BattleFormation.skirmish,
        BattleFormation.skirmish => BattleFormation.shieldWall,
      };

  /// Calculate overall effectiveness modifier against enemy formation.
  /// Returns 1.02 if winning, 0.98 if losing, 1.0 if mirror.
  double bonusAgainst(BattleFormation enemy) {
    if (beats == enemy) return 1.02;
    if (enemy.beats == this) return 0.98;
    return 1.0;
  }

  /// Formation-specific stat modifiers (balanced values).
  FormationModifiers get modifiers => switch (this) {
        BattleFormation.shieldWall => const FormationModifiers(
            infantryDefenseBonus: 0.03, // +3% defense
            rangedRangeBonus: 1,
            cavalryChargeMultiplier: 0.95, // -5% own cavalry charge
            speedMultiplier: 0.97, // -3% speed
          ),
        BattleFormation.crescent => const FormationModifiers(
            cavalryChargeMultiplier: 1.05, // +5% charge bonus
            infantryDefenseBonus: -0.02, // Infantry slightly exposed
            rangedDefenseBonus: -0.02,
          ),
        BattleFormation.skirmish => const FormationModifiers(
            speedMultiplier: 1.03, // +3% speed
            rangedRangeBonus: 1,
            rangedDamageTakenMultiplier: 0.97, // -3% damage from enemy ranged
            meleeAttackMultiplier: 0.98, // -2% melee attack
            enemyChargeMultiplier: 0.97, // -3% enemy charge effectiveness
          ),
      };
}

/// Formation-specific modifiers applied to units.
class FormationModifiers {
  final double infantryDefenseBonus; // Additive defense %
  final double rangedDefenseBonus;
  final int rangedRangeBonus; // Additive range units
  final double cavalryChargeMultiplier; // Multiplier on own cavalry charge
  final double speedMultiplier; // Multiplier on movement speed
  final double rangedDamageTakenMultiplier; // Damage taken from enemy ranged
  final double meleeAttackMultiplier; // Multiplier on melee attack
  final double enemyChargeMultiplier; // Multiplier on enemy charge effectiveness
  final double flankDamageBonus; // Bonus damage when flanking (Crescent)

  const FormationModifiers({
    this.infantryDefenseBonus = 0.0,
    this.rangedDefenseBonus = 0.0,
    this.rangedRangeBonus = 0,
    this.cavalryChargeMultiplier = 1.0,
    this.speedMultiplier = 1.0,
    this.rangedDamageTakenMultiplier = 1.0,
    this.meleeAttackMultiplier = 1.0,
    this.enemyChargeMultiplier = 1.0,
    this.flankDamageBonus = 0.0,
  });
}

/// Complete battle record with phase-based combat.
class BattleRecord {
  final String id;
  final String attackerName;
  final String defenderName;
  final String attackerId;
  final String defenderId;
  final String attackerOwnerId; // Who owned attacker at battle time
  final String defenderOwnerId; // Who owned defender at battle time
  final String? originVillageId;
  final String locationName;
  final List<BattleRound> rounds; // Legacy compatibility
  final List<PhaseResult> phases; // New phase-based results
  final bool attackerWon;
  final int initialAttackerCount;
  final int initialDefenderCount;
  final int initialGarrisonCount;
  final DateTime timestamp;
  bool isPending;

  // New combat data
  final BattleTerrain? terrain;
  final BattleFormation? attackerFormation;
  final BattleFormation? defenderFormation;
  final double formationBonus; // Attacker's formation modifier
  final int attackerBarracksLevel;
  final int attackerArcheryLevel;
  final int attackerStablesLevel;
  final int defenderBarracksLevel;
  final int defenderArcheryLevel;
  final int defenderStablesLevel;

  BattleRecord({
    required this.id,
    required this.attackerName,
    required this.defenderName,
    required this.attackerId,
    required this.defenderId,
    required this.attackerOwnerId,
    required this.defenderOwnerId,
    this.originVillageId,
    required this.locationName,
    required this.rounds,
    this.phases = const [],
    required this.attackerWon,
    required this.initialAttackerCount,
    required this.initialDefenderCount,
    this.initialGarrisonCount = 0,
    DateTime? timestamp,
    this.isPending = true,
    this.terrain,
    this.attackerFormation,
    this.defenderFormation,
    this.formationBonus = 1.0,
    this.attackerBarracksLevel = 0,
    this.attackerArcheryLevel = 0,
    this.attackerStablesLevel = 0,
    this.defenderBarracksLevel = 0,
    this.defenderArcheryLevel = 0,
    this.defenderStablesLevel = 0,
  }) : timestamp = timestamp ?? DateTime.now();

  int get totalAttackerLosses =>
      phases.isNotEmpty
          ? phases.fold(0, (sum, p) => sum + p.defenderKills)
          : rounds.fold(0, (sum, r) => sum + r.attackerLosses);

  int get totalDefenderLosses =>
      phases.isNotEmpty
          ? phases.fold(0, (sum, p) => sum + p.attackerKills)
          : rounds.fold(0, (sum, r) => sum + r.defenderLosses);

  /// Get kills by phase for display.
  Map<CombatPhase, (int attackerKills, int defenderKills)> get killsByPhase {
    final result = <CombatPhase, (int, int)>{};
    for (final phase in phases) {
      result[phase.phase] = (phase.attackerKills, phase.defenderKills);
    }
    return result;
  }
}
