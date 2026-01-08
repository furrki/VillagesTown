import 'dart:math';
import '../data/map/game_map.dart';
import '../data/models/unit.dart';
import '../data/models/unit_type.dart';
import '../data/models/village.dart';
import '../data/models/combat_log.dart';

/// Phase-based combat engine with stat-based kills.
///
/// Combat loops through three phases until one side is eliminated:
/// 1. Ranged Volley - Archers fire (accuracy-based hits)
/// 2. Cavalry Charge - Cavalry sweep (kill potential)
/// 3. Melee Clash - Infantry grind (kill rate attrition)
///
/// Each phase rolls luck (d100 → 0.85-1.15 modifier).
/// Formation bonuses apply throughout (+30% / -30%).
/// Fortress bonuses reduce attacker cavalry and boost defender.
class CombatEngine {
  final Random _random = Random();

  /// Maximum combat rounds to prevent infinite loops.
  static const int maxRounds = 10;

  /// Convert d100 roll to luck modifier (0.85 to 1.15).
  double _luckModifier(int d100) {
    return 0.85 + (d100 / 100.0) * 0.30;
  }

  /// Roll d100 for luck.
  int _rollLuck() => _random.nextInt(100) + 1;

  /// Fortress modifier for attacker cavalry (walls negate charges).
  double _fortressCavalryPenalty(int fortressLevel) => switch (fortressLevel) {
    1 => 0.7,
    2 => 0.5,
    >= 3 => 0.3,
    _ => 1.0,
  };

  /// Fortress modifier for defender (defensive bonus).
  double _fortressDefenderBonus(int fortressLevel) => switch (fortressLevel) {
    1 => 1.10,
    2 => 1.20,
    >= 3 => 1.30,
    _ => 1.0,
  };

  /// Fortress penalty for attacker archers (shooting uphill at walls).
  double _fortressArcherPenalty(int fortressLevel) => fortressLevel >= 3 ? 0.90 : 1.0;

  /// Main combat resolution with phase-based system.
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
    BattleFormation attackerFormation = BattleFormation.romanFormation,
    BattleFormation defenderFormation = BattleFormation.romanFormation,
    int attackerBarracksLevel = 0,
    int attackerArcheryLevel = 0,
    int attackerStablesLevel = 0,
    int defenderBarracksLevel = 0,
    int defenderArcheryLevel = 0,
    int defenderStablesLevel = 0,
    int defenderFortressLevel = 0,
  }) {
    final phases = <PhaseResult>[];
    final initialAttackerCount = attackers.length;
    final initialDefenderCount = defenders.length;

    // Create mutable lists for tracking casualties
    final attackerUnits = List<Unit>.from(attackers);
    final defenderUnits = List<Unit>.from(defenders);

    // Calculate formation modifier (attacker's perspective)
    final formationMod = attackerFormation.bonusAgainst(defenderFormation);
    final defenderFormationMod = defenderFormation.bonusAgainst(attackerFormation);

    // Calculate fortress modifiers
    final fortressCavPenalty = _fortressCavalryPenalty(defenderFortressLevel);
    final fortressDefBonus = _fortressDefenderBonus(defenderFortressLevel);
    final fortressArcherPenalty = _fortressArcherPenalty(defenderFortressLevel);

    // Combat loop - all 3 phases repeat until one side eliminated
    int round = 0;
    while (attackerUnits.isNotEmpty && defenderUnits.isNotEmpty && round < maxRounds) {
      round++;

      // --- PHASE 1: RANGED VOLLEY ---
      final rangedResult = _resolveRangedPhase(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        attackerFormationMod: formationMod * fortressArcherPenalty,
        defenderFormationMod: defenderFormationMod * fortressDefBonus,
        attackerArcheryLevel: attackerArcheryLevel,
        defenderArcheryLevel: defenderArcheryLevel,
      );
      phases.add(rangedResult);
      _applyCasualties(attackerUnits, rangedResult.defenderKills, _targetPriority);
      _applyCasualties(defenderUnits, rangedResult.attackerKills, _targetPriority);

      if (attackerUnits.isEmpty || defenderUnits.isEmpty) break;

      // --- PHASE 2: CAVALRY CHARGE ---
      final cavalryResult = _resolveCavalryPhase(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        attackerFormationMod: formationMod * fortressCavPenalty,
        defenderFormationMod: defenderFormationMod * fortressDefBonus,
        attackerStablesLevel: attackerStablesLevel,
        defenderStablesLevel: defenderStablesLevel,
      );
      phases.add(cavalryResult);
      _applyCasualties(defenderUnits, cavalryResult.attackerKills, _cavalryTargetPriority);
      _applyCasualties(attackerUnits, cavalryResult.defenderKills, _cavalryTargetPriority);

      if (attackerUnits.isEmpty || defenderUnits.isEmpty) break;

      // --- PHASE 3: MELEE CLASH ---
      final meleeResult = _resolveMeleePhase(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        attackerFormationMod: formationMod,
        defenderFormationMod: defenderFormationMod * fortressDefBonus,
        attackerBarracksLevel: attackerBarracksLevel,
        defenderBarracksLevel: defenderBarracksLevel,
      );
      phases.add(meleeResult);
      // Melee casualties: infantry and cavalry die first, archers only if overrun
      _applyCasualties(defenderUnits, meleeResult.attackerKills, _meleeTargetPriority);
      _applyCasualties(attackerUnits, meleeResult.defenderKills, _meleeTargetPriority);
    }

    // Determine winner
    final attackerWon = defenderUnits.isEmpty ||
        (attackerUnits.isNotEmpty && attackerUnits.length > defenderUnits.length);

    // Create legacy rounds for compatibility
    final legacyRounds = _createLegacyRounds(phases);

    return BattleRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      attackerName: attackerName,
      defenderName: defenderName,
      attackerId: attackerId,
      defenderId: defenderId,
      originVillageId: originVillageId,
      locationName: defendingVillage?.name ?? 'Open Field',
      rounds: legacyRounds,
      phases: phases,
      attackerWon: attackerWon,
      initialAttackerCount: initialAttackerCount,
      initialDefenderCount: initialDefenderCount,
      initialGarrisonCount: garrisonCount,
      attackerFormation: attackerFormation,
      defenderFormation: defenderFormation,
      formationBonus: formationMod,
      attackerBarracksLevel: attackerBarracksLevel,
      attackerArcheryLevel: attackerArcheryLevel,
      attackerStablesLevel: attackerStablesLevel,
      defenderBarracksLevel: defenderBarracksLevel,
      defenderArcheryLevel: defenderArcheryLevel,
      defenderStablesLevel: defenderStablesLevel,
    );
  }

  /// Target priority for ranged phase: infantry first (they're the frontline).
  List<String> get _targetPriority => ['Infantry', 'Ranged', 'Cavalry'];

  /// Cavalry targets ranged first (soft targets), then infantry.
  List<String> get _cavalryTargetPriority => ['Ranged', 'Infantry', 'Cavalry'];

  /// Melee priority: infantry and cavalry fight, archers only die if overrun.
  List<String> get _meleeTargetPriority => ['Infantry', 'Cavalry', 'Ranged'];

  /// Resolve ranged phase: archers fire based on accuracy.
  PhaseResult _resolveRangedPhase({
    required List<Unit> attackerUnits,
    required List<Unit> defenderUnits,
    required double attackerFormationMod,
    required double defenderFormationMod,
    required int attackerArcheryLevel,
    required int defenderArcheryLevel,
  }) {
    final attackerLuckRoll = _rollLuck();
    final defenderLuckRoll = _rollLuck();
    final attackerLuck = _luckModifier(attackerLuckRoll);
    final defenderLuck = _luckModifier(defenderLuckRoll);

    // Get ranged units
    final attackerArchers = attackerUnits.where((u) => u.unitType.category == 'Ranged').toList();
    final defenderArchers = defenderUnits.where((u) => u.unitType.category == 'Ranged').toList();

    // Calculate kills
    int attackerKills = 0;
    int defenderKills = 0;

    // Attacker archers fire
    for (final archer in attackerArchers) {
      final baseAccuracy = archer.unitType.baseAccuracy;
      final bonusAccuracy = attackerArcheryLevel * 0.03;
      final finalAccuracy = min(0.90, (baseAccuracy + bonusAccuracy) * attackerLuck * attackerFormationMod);
      if (_random.nextDouble() < finalAccuracy) {
        attackerKills++;
      }
    }

    // Defender archers fire
    for (final archer in defenderArchers) {
      final baseAccuracy = archer.unitType.baseAccuracy;
      final bonusAccuracy = defenderArcheryLevel * 0.03;
      final finalAccuracy = min(0.90, (baseAccuracy + bonusAccuracy) * defenderLuck * defenderFormationMod);
      if (_random.nextDouble() < finalAccuracy) {
        defenderKills++;
      }
    }

    // Generate narration
    String narration = '';
    if (attackerKills > 0 && defenderKills > 0) {
      narration = '${attackerArchers.length} archers hit $attackerKills, ${defenderArchers.length} return fire hitting $defenderKills';
    } else if (attackerKills > 0) {
      narration = '${attackerArchers.length} archers rain arrows, killing $attackerKills defenders';
    } else if (defenderKills > 0) {
      narration = '${defenderArchers.length} defenders fire a volley, killing $defenderKills attackers';
    } else if (attackerArchers.isEmpty && defenderArchers.isEmpty) {
      narration = 'No ranged units present';
    } else {
      narration = 'Arrows fly but find no targets';
    }

    return PhaseResult(
      phase: CombatPhase.ranged,
      attackerLuckRoll: attackerLuckRoll,
      defenderLuckRoll: defenderLuckRoll,
      attackerLuckModifier: attackerLuck,
      defenderLuckModifier: defenderLuck,
      attackerKills: attackerKills,
      defenderKills: defenderKills,
      attackerCasualtiesByType: {},
      defenderCasualtiesByType: {},
      narration: narration,
    );
  }

  /// Resolve cavalry phase: cavalry charge with kill potential.
  PhaseResult _resolveCavalryPhase({
    required List<Unit> attackerUnits,
    required List<Unit> defenderUnits,
    required double attackerFormationMod,
    required double defenderFormationMod,
    required int attackerStablesLevel,
    required int defenderStablesLevel,
  }) {
    final attackerLuckRoll = _rollLuck();
    final defenderLuckRoll = _rollLuck();
    final attackerLuck = _luckModifier(attackerLuckRoll);
    final defenderLuck = _luckModifier(defenderLuckRoll);

    // Get cavalry units
    final attackerCav = attackerUnits.where((u) => u.unitType.category == 'Cavalry').toList();
    final defenderCav = defenderUnits.where((u) => u.unitType.category == 'Cavalry').toList();

    // Check for spearmen counters
    final defenderHasSpearmen = defenderUnits.any((u) => u.unitType == UnitType.spearman);
    final attackerHasSpearmen = attackerUnits.any((u) => u.unitType == UnitType.spearman);

    // Calculate kills
    double attackerKillsRaw = 0;
    double defenderKillsRaw = 0;

    // Attacker cavalry charge
    for (final cav in attackerCav) {
      final basePotential = cav.unitType.baseKillPotential;
      final bonusPotential = attackerStablesLevel * 0.1;
      double counterMod = defenderHasSpearmen ? 0.5 : 1.0; // Spearmen counter cavalry
      final finalPotential = (basePotential + bonusPotential) * attackerLuck * attackerFormationMod * counterMod;
      attackerKillsRaw += finalPotential;
    }

    // Defender cavalry counter-charge
    for (final cav in defenderCav) {
      final basePotential = cav.unitType.baseKillPotential;
      final bonusPotential = defenderStablesLevel * 0.1;
      double counterMod = attackerHasSpearmen ? 0.5 : 1.0;
      final finalPotential = (basePotential + bonusPotential) * defenderLuck * defenderFormationMod * counterMod;
      defenderKillsRaw += finalPotential;
    }

    final attackerKills = attackerKillsRaw.floor();
    final defenderKills = defenderKillsRaw.floor();

    // Generate narration
    String narration = '';
    if (attackerKills > 0 && defenderKills > 0) {
      narration = '${attackerCav.length} cavalry sweep through, killing $attackerKills; ${defenderCav.length} counter-charge killing $defenderKills';
    } else if (attackerKills > 0) {
      narration = '${attackerCav.length} cavalry crash into enemy lines, killing $attackerKills';
    } else if (defenderKills > 0) {
      narration = '${defenderCav.length} defender cavalry charge, killing $defenderKills';
    } else if (attackerCav.isEmpty && defenderCav.isEmpty) {
      narration = 'No cavalry engaged';
    } else {
      narration = 'Cavalry charges falter against spearmen';
    }

    return PhaseResult(
      phase: CombatPhase.cavalry,
      attackerLuckRoll: attackerLuckRoll,
      defenderLuckRoll: defenderLuckRoll,
      attackerLuckModifier: attackerLuck,
      defenderLuckModifier: defenderLuck,
      attackerKills: attackerKills,
      defenderKills: defenderKills,
      attackerCasualtiesByType: {},
      defenderCasualtiesByType: {},
      narration: narration,
    );
  }

  /// Resolve melee phase: infantry and cavalry grind.
  /// Archers hold position in rear - they don't fight in melee unless overrun.
  PhaseResult _resolveMeleePhase({
    required List<Unit> attackerUnits,
    required List<Unit> defenderUnits,
    required double attackerFormationMod,
    required double defenderFormationMod,
    required int attackerBarracksLevel,
    required int defenderBarracksLevel,
  }) {
    final attackerLuckRoll = _rollLuck();
    final defenderLuckRoll = _rollLuck();
    final attackerLuck = _luckModifier(attackerLuckRoll);
    final defenderLuck = _luckModifier(defenderLuckRoll);

    // Only Infantry and Cavalry fight in melee - archers hold position
    final attackerMeleeUnits = attackerUnits.where((u) => u.unitType.category != 'Ranged').toList();
    final defenderMeleeUnits = defenderUnits.where((u) => u.unitType.category != 'Ranged').toList();

    double attackerKillsRaw = 0;
    double defenderKillsRaw = 0;

    // Calculate cavalry ratios for spearmen bonus
    final defenderCavalryRatio = defenderMeleeUnits.where((u) => u.unitType.category == 'Cavalry').length / max(1, defenderMeleeUnits.length);
    final attackerCavalryRatio = attackerMeleeUnits.where((u) => u.unitType.category == 'Cavalry').length / max(1, attackerMeleeUnits.length);

    // Attacker melee (only infantry and cavalry fight)
    for (final unit in attackerMeleeUnits) {
      final baseRate = unit.unitType.baseKillRate;
      final bonusRate = unit.unitType.category == 'Infantry'
          ? attackerBarracksLevel * 0.02
          : 0.0;

      // Spearmen bonus vs cavalry
      double counterMod = 1.0;
      if (unit.unitType == UnitType.spearman) {
        counterMod = 1.0 + (0.5 * defenderCavalryRatio);
      }

      final finalRate = (baseRate + bonusRate) * attackerLuck * attackerFormationMod * counterMod;
      attackerKillsRaw += finalRate;
    }

    // Defender melee (only infantry and cavalry fight)
    for (final unit in defenderMeleeUnits) {
      final baseRate = unit.unitType.baseKillRate;
      final bonusRate = unit.unitType.category == 'Infantry'
          ? defenderBarracksLevel * 0.02
          : 0.0;

      double counterMod = 1.0;
      if (unit.unitType == UnitType.spearman) {
        counterMod = 1.0 + (0.5 * attackerCavalryRatio);
      }

      final finalRate = (baseRate + bonusRate) * defenderLuck * defenderFormationMod * counterMod;
      defenderKillsRaw += finalRate;
    }

    final attackerKills = attackerKillsRaw.floor();
    final defenderKills = defenderKillsRaw.floor();

    // Count archers holding position
    final attackerArchers = attackerUnits.where((u) => u.unitType.category == 'Ranged').length;
    final defenderArchers = defenderUnits.where((u) => u.unitType.category == 'Ranged').length;

    // Generate narration
    String narration = '';
    if (attackerMeleeUnits.isEmpty && defenderMeleeUnits.isEmpty) {
      narration = 'No melee troops engage - archers hold position';
    } else if (attackerKills > 0 && defenderKills > 0) {
      narration = 'Fierce melee: attackers kill $attackerKills, defenders kill $defenderKills';
    } else if (attackerKills > 0) {
      narration = 'Attackers cut through defenders, killing $attackerKills';
    } else if (defenderKills > 0) {
      narration = 'Defenders hold firm, killing $defenderKills attackers';
    } else if (attackerMeleeUnits.isEmpty && attackerArchers > 0) {
      narration = 'Attacker archers hold position as infantry is depleted';
    } else if (defenderMeleeUnits.isEmpty && defenderArchers > 0) {
      narration = 'Defender archers hold as their line breaks';
    } else {
      narration = 'The melee is inconclusive';
    }

    return PhaseResult(
      phase: CombatPhase.melee,
      attackerLuckRoll: attackerLuckRoll,
      defenderLuckRoll: defenderLuckRoll,
      attackerLuckModifier: attackerLuck,
      defenderLuckModifier: defenderLuck,
      attackerKills: attackerKills,
      defenderKills: defenderKills,
      attackerCasualtiesByType: {},
      defenderCasualtiesByType: {},
      narration: narration,
    );
  }

  /// Apply casualties to a unit list based on priority.
  void _applyCasualties(List<Unit> units, int casualties, List<String> priority) {
    int remaining = casualties;

    for (final category in priority) {
      if (remaining <= 0) break;

      final targetUnits = units.where((u) => u.unitType.category == category).toList();
      final toRemove = min(remaining, targetUnits.length);

      for (int i = 0; i < toRemove; i++) {
        units.remove(targetUnits[i]);
        remaining--;
      }
    }

    // If still remaining (shouldn't happen), remove any
    while (remaining > 0 && units.isNotEmpty) {
      units.removeLast();
      remaining--;
    }
  }

  /// Create legacy BattleRound objects for compatibility.
  List<BattleRound> _createLegacyRounds(List<PhaseResult> phases) {
    return phases.map((p) => BattleRound(
      attackerRolls: [p.attackerLuckRoll],
      defenderRolls: [p.defenderLuckRoll],
      attackerBonus: 0,
      defenderBonus: 0,
      attackerLosses: p.defenderKills,
      defenderLosses: p.attackerKills,
      narration: p.narration,
    )).toList();
  }
}
