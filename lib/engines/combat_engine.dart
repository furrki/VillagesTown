import 'dart:math';
import '../data/map/game_map.dart';
import '../data/models/unit.dart';
import '../data/models/unit_type.dart';
import '../data/models/village.dart';
import '../data/models/combat_log.dart';

/// Combat unit state during battle - tracks individual soldier.
class CombatUnit {
  final String id;
  final Unit unit;
  final bool isAttacker;
  final bool isGarrison; // Garrison units are 30% weaker
  int hp;
  double attackCooldown; // Seconds until next attack
  double position; // 0.0 = own side, 1.0 = enemy side (for range calc)
  CombatUnit? currentTarget;
  bool isRouting = false;
  bool isDead = false;

  CombatUnit({
    required this.id,
    required this.unit,
    required this.isAttacker,
    this.isGarrison = false,
  })  : hp = unit.maxHP,
        attackCooldown = 0,
        position = isAttacker ? 0.0 : 1.0;

  UnitType get type => unit.unitType;
  String get category => type.category;
  bool get isRanged => category == 'Ranged';
  bool get isCavalry => category == 'Cavalry';
  bool get isInfantry => category == 'Infantry';
  bool get isAlive => !isDead && hp > 0;

  /// Attack speed in seconds (lower = faster).
  double get attackInterval => switch (type) {
        UnitType.archer => 2.0,
        UnitType.crossbowman => 2.5, // Slower but harder hitting
        UnitType.lightCavalry => 1.2,
        UnitType.knight => 1.5,
        UnitType.swordsman => 1.0,
        UnitType.spearman => 1.3,
        UnitType.militia => 1.4,
      };

  /// Attack range (0.0-1.0 distance scale).
  double get attackRange => switch (category) {
        'Ranged' => 0.8, // Can attack from far
        'Cavalry' => 0.3, // Medium range (charging)
        _ => 0.15, // Melee only
      };

  /// Base damage per attack.
  int get baseDamage => switch (type) {
        UnitType.archer => 15 + unit.bonusAttack,
        UnitType.crossbowman => 25 + unit.bonusAttack,
        UnitType.lightCavalry => 20 + unit.bonusAttack,
        UnitType.knight => 35 + unit.bonusAttack,
        UnitType.swordsman => 18 + unit.bonusAttack,
        UnitType.spearman => 14 + unit.bonusAttack,
        UnitType.militia => 10 + unit.bonusAttack,
      };

  /// Movement speed (distance per second).
  double get moveSpeed => switch (category) {
        'Cavalry' => 0.25,
        'Infantry' => 0.12,
        'Ranged' => 0.08, // Archers move slowly, prefer distance
        _ => 0.10,
      };
}

/// A single combat event for visualization.
class CombatEvent {
  final double timestamp;
  final CombatEventType eventType;
  final String? attackerId;
  final String? targetId;
  final int damage;
  final bool isCrit;
  final String? message;

  CombatEvent({
    required this.timestamp,
    required this.eventType,
    this.attackerId,
    this.targetId,
    this.damage = 0,
    this.isCrit = false,
    this.message,
  });
}

enum CombatEventType {
  attack,
  kill,
  rout,
  charge, // Cavalry charge bonus
  volley, // Ranged volley
  meleeClash,
  victory,
  defeat,
}

/// Tick-based continuous combat engine.
/// Simulates real-time battle where units attack independently based on cooldowns.
class CombatEngine {
  final Random _random = Random();

  /// Simulation tick rate (seconds per tick).
  static const double tickRate = 0.1;

  /// Maximum battle duration (seconds).
  static const double maxBattleDuration = 60.0;

  /// Morale thresholds
  static const double startingMorale = 100.0;
  static const double routThreshold = 20.0;
  static const double moraleLossPerDeath = 5.0;
  static const double moraleGainPerKill = 2.0;

  /// Fortress modifiers
  double _fortressDamageReduction(int level) => switch (level) {
        1 => 0.90,
        2 => 0.80,
        >= 3 => 0.70,
        _ => 1.0,
      };

  double _fortressCavalryPenalty(int level) => switch (level) {
        1 => 0.70,
        2 => 0.50,
        >= 3 => 0.30,
        _ => 1.0,
      };

  /// Main combat resolution - continuous tick-based simulation.
  BattleRecord resolveCombat({
    required String attackerName,
    required String defenderName,
    required String attackerId,
    required String defenderId,
    required String attackerOwnerId,
    required String defenderOwnerId,
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
    final events = <CombatEvent>[];
    final initialAttackerCount = attackers.length;
    final initialDefenderCount = defenders.length;

    // Create combat units
    final attackerUnits = <CombatUnit>[];
    final defenderUnits = <CombatUnit>[];

    for (int i = 0; i < attackers.length; i++) {
      attackerUnits.add(CombatUnit(
        id: 'atk_$i',
        unit: attackers[i],
        isAttacker: true,
      ));
    }

    // Garrison units are the last garrisonCount defenders (appended at end)
    final garrisonStartIndex = defenders.length - garrisonCount;
    for (int i = 0; i < defenders.length; i++) {
      defenderUnits.add(CombatUnit(
        id: 'def_$i',
        unit: defenders[i],
        isAttacker: false,
        isGarrison: i >= garrisonStartIndex,
      ));
    }

    // Morale tracking
    double attackerMorale = startingMorale;
    double defenderMorale = startingMorale;

    // Formation modifier
    final formationMod = attackerFormation.bonusAgainst(defenderFormation);
    final defenderFormationMod = defenderFormation.bonusAgainst(attackerFormation);

    // Fortress modifiers for defenders
    final fortressDmgReduction = _fortressDamageReduction(defenderFortressLevel);
    final fortressCavPenalty = _fortressCavalryPenalty(defenderFortressLevel);

    // Simulation state
    double currentTime = 0;
    bool battleEnded = false;
    bool attackerWon = false;

    // Initial charge event
    if (attackerUnits.any((u) => u.isCavalry)) {
      events.add(CombatEvent(
        timestamp: 0,
        eventType: CombatEventType.charge,
        message: 'Cavalry charges!',
      ));
    }

    // Main simulation loop
    while (!battleEnded && currentTime < maxBattleDuration) {
      currentTime += tickRate;

      final aliveAttackers = attackerUnits.where((u) => u.isAlive && !u.isRouting).toList();
      final aliveDefenders = defenderUnits.where((u) => u.isAlive && !u.isRouting).toList();

      // Check win conditions
      if (aliveAttackers.isEmpty) {
        battleEnded = true;
        attackerWon = false;
        events.add(CombatEvent(
          timestamp: currentTime,
          eventType: CombatEventType.defeat,
          message: 'Attackers eliminated!',
        ));
        break;
      }

      if (aliveDefenders.isEmpty) {
        battleEnded = true;
        attackerWon = true;
        events.add(CombatEvent(
          timestamp: currentTime,
          eventType: CombatEventType.victory,
          message: 'Defenders eliminated!',
        ));
        break;
      }

      // Process each attacker unit
      // Attackers deal REDUCED damage when attacking a fortress (walls protect defenders)
      for (final unit in aliveAttackers) {
        _processUnitTick(
          unit: unit,
          enemies: aliveDefenders,
          allies: aliveAttackers,
          events: events,
          currentTime: currentTime,
          formationMod: formationMod,
          fortressDmgReduction: fortressDmgReduction, // Fortress walls reduce attacker damage
          fortressCavPenalty: fortressCavPenalty,
          morale: attackerMorale,
        );
      }

      // Process each defender unit
      // Defenders deal full damage (fortress doesn't penalize their attacks)
      for (final unit in aliveDefenders) {
        _processUnitTick(
          unit: unit,
          enemies: aliveAttackers,
          allies: aliveDefenders,
          events: events,
          currentTime: currentTime,
          formationMod: defenderFormationMod,
          fortressDmgReduction: 1.0, // Defenders deal full damage
          fortressCavPenalty: 1.0,
          morale: defenderMorale,
        );
      }

      // Update morale based on recent deaths
      final recentAttackerDeaths = attackerUnits.where((u) => u.isDead).length;
      final recentDefenderDeaths = defenderUnits.where((u) => u.isDead).length;

      attackerMorale = startingMorale -
          (recentAttackerDeaths * moraleLossPerDeath) +
          (recentDefenderDeaths * moraleGainPerKill * 0.5);
      defenderMorale = startingMorale -
          (recentDefenderDeaths * moraleLossPerDeath) +
          (recentAttackerDeaths * moraleGainPerKill * 0.5);

      attackerMorale = attackerMorale.clamp(0, 100);
      defenderMorale = defenderMorale.clamp(0, 100);

      // Check for routing
      if (attackerMorale < routThreshold) {
        for (final unit in aliveAttackers) {
          if (!unit.isRouting && _random.nextDouble() < 0.3) {
            unit.isRouting = true;
            events.add(CombatEvent(
              timestamp: currentTime,
              eventType: CombatEventType.rout,
              attackerId: unit.id,
              message: '${unit.type.displayName} flees!',
            ));
          }
        }
      }

      if (defenderMorale < routThreshold) {
        for (final unit in aliveDefenders) {
          if (!unit.isRouting && _random.nextDouble() < 0.3) {
            unit.isRouting = true;
            events.add(CombatEvent(
              timestamp: currentTime,
              eventType: CombatEventType.rout,
              attackerId: unit.id,
              message: '${unit.type.displayName} flees!',
            ));
          }
        }
      }

      // Move units toward engagement
      for (final unit in aliveAttackers) {
        if (!unit.isRouting) {
          unit.position = min(1.0, unit.position + unit.moveSpeed * tickRate);
        }
      }
      for (final unit in aliveDefenders) {
        if (!unit.isRouting) {
          unit.position = max(0.0, unit.position - unit.moveSpeed * tickRate);
        }
      }
    }

    // Determine final outcome if battle timed out
    if (!battleEnded) {
      final remainingAttackers = attackerUnits.where((u) => u.isAlive).length;
      final remainingDefenders = defenderUnits.where((u) => u.isAlive).length;
      attackerWon = remainingAttackers > remainingDefenders;
    }

    // NOTE: We do NOT modify original unit lists here.
    // finalizeBattle() handles casualty application based on rounds played.
    // This allows partial battles (retreat) to apply fewer casualties.

    // Create legacy phases for compatibility with existing UI
    final phases = _createPhasesFromEvents(events, initialAttackerCount, initialDefenderCount);
    final legacyRounds = _createLegacyRounds(phases);

    return BattleRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      attackerName: attackerName,
      defenderName: defenderName,
      attackerId: attackerId,
      defenderId: defenderId,
      attackerOwnerId: attackerOwnerId,
      defenderOwnerId: defenderOwnerId,
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

  /// Process a single unit's tick - attack if ready, find target, etc.
  void _processUnitTick({
    required CombatUnit unit,
    required List<CombatUnit> enemies,
    required List<CombatUnit> allies,
    required List<CombatEvent> events,
    required double currentTime,
    required double formationMod,
    required double fortressDmgReduction,
    required double fortressCavPenalty,
    required double morale,
  }) {
    // Reduce cooldown
    unit.attackCooldown = max(0, unit.attackCooldown - tickRate);

    // Can't attack if on cooldown
    if (unit.attackCooldown > 0) return;

    // Find target
    final target = _findTarget(unit, enemies);
    if (target == null) return;

    // Check range
    final distance = (unit.position - target.position).abs();
    if (distance > unit.attackRange) return;

    // Execute attack
    unit.attackCooldown = unit.attackInterval;

    // Calculate damage
    double damage = unit.baseDamage.toDouble();

    // Apply formation modifier
    damage *= formationMod;

    // Apply fortress damage reduction (attackers deal less damage to fortified defenders)
    damage *= fortressDmgReduction;

    // Cavalry penalty vs fortress
    if (unit.isCavalry) {
      damage *= fortressCavPenalty;
    }

    // Counter bonuses
    damage *= unit.type.damageMultiplier(target.type);

    // Garrison units are 30% weaker (untrained militia)
    if (unit.isGarrison) {
      damage *= 0.7;
    }

    // Morale modifier (low morale = weaker attacks)
    damage *= (0.5 + morale / 200.0);

    // Accuracy for ranged (chance to miss)
    if (unit.isRanged) {
      final accuracy = min(0.90, unit.type.baseAccuracy + unit.unit.bonusAccuracy);
      if (_random.nextDouble() > accuracy) {
        // Miss - no event needed for every miss
        return;
      }
    }

    // Critical hit chance (10%)
    final isCrit = _random.nextDouble() < 0.10;
    if (isCrit) {
      damage *= 1.5;
    }

    // Apply damage
    final finalDamage = max(1, damage.round());
    target.hp -= finalDamage;

    // Record attack event (not every single one to avoid spam)
    if (_random.nextDouble() < 0.3 || isCrit || target.hp <= 0) {
      events.add(CombatEvent(
        timestamp: currentTime,
        eventType: CombatEventType.attack,
        attackerId: unit.id,
        targetId: target.id,
        damage: finalDamage,
        isCrit: isCrit,
      ));
    }

    // Check for kill
    if (target.hp <= 0) {
      target.isDead = true;
      events.add(CombatEvent(
        timestamp: currentTime,
        eventType: CombatEventType.kill,
        attackerId: unit.id,
        targetId: target.id,
        message: '${unit.type.displayName} kills ${target.type.displayName}!',
      ));
    }
  }

  /// Find the best target for a unit.
  CombatUnit? _findTarget(CombatUnit unit, List<CombatUnit> enemies) {
    final validTargets = enemies.where((e) => e.isAlive && !e.isRouting).toList();
    if (validTargets.isEmpty) return null;

    // Priority targeting based on unit type
    if (unit.isCavalry) {
      // Cavalry prioritize ranged units
      final ranged = validTargets.where((e) => e.isRanged).toList();
      if (ranged.isNotEmpty) {
        return ranged[_random.nextInt(ranged.length)];
      }
    } else if (unit.isRanged) {
      // Archers prioritize infantry (easier targets)
      final infantry = validTargets.where((e) => e.isInfantry).toList();
      if (infantry.isNotEmpty) {
        return infantry[_random.nextInt(infantry.length)];
      }
    }

    // Default: closest target by position
    validTargets.sort((a, b) {
      final distA = (unit.position - a.position).abs();
      final distB = (unit.position - b.position).abs();
      return distA.compareTo(distB);
    });

    return validTargets.first;
  }

  /// Create phase summaries from combat events for UI compatibility.
  List<PhaseResult> _createPhasesFromEvents(
    List<CombatEvent> events,
    int initialAttackers,
    int initialDefenders,
  ) {
    final phases = <PhaseResult>[];

    // Ranged phase (first third of battle)
    final rangedEvents = events.where((e) => e.timestamp < 20).toList();
    final rangedAttackerKills = rangedEvents
        .where((e) => e.eventType == CombatEventType.kill && (e.attackerId?.startsWith('atk_') ?? false))
        .length;
    final rangedDefenderKills = rangedEvents
        .where((e) => e.eventType == CombatEventType.kill && (e.attackerId?.startsWith('def_') ?? false))
        .length;

    phases.add(PhaseResult(
      phase: CombatPhase.ranged,
      attackerLuckRoll: 50 + _random.nextInt(50),
      defenderLuckRoll: 50 + _random.nextInt(50),
      attackerLuckModifier: 1.0,
      defenderLuckModifier: 1.0,
      attackerKills: rangedAttackerKills,
      defenderKills: rangedDefenderKills,
      attackerCasualtiesByType: {},
      defenderCasualtiesByType: {},
      narration: rangedAttackerKills + rangedDefenderKills > 0
          ? 'Arrows fly as the battle begins!'
          : 'The armies close in!',
    ));

    // Cavalry phase (middle)
    final cavalryEvents = events.where((e) => e.timestamp >= 20 && e.timestamp < 40).toList();
    final cavAttackerKills = cavalryEvents
        .where((e) => e.eventType == CombatEventType.kill && (e.attackerId?.startsWith('atk_') ?? false))
        .length;
    final cavDefenderKills = cavalryEvents
        .where((e) => e.eventType == CombatEventType.kill && (e.attackerId?.startsWith('def_') ?? false))
        .length;

    phases.add(PhaseResult(
      phase: CombatPhase.cavalry,
      attackerLuckRoll: 50 + _random.nextInt(50),
      defenderLuckRoll: 50 + _random.nextInt(50),
      attackerLuckModifier: 1.0,
      defenderLuckModifier: 1.0,
      attackerKills: cavAttackerKills,
      defenderKills: cavDefenderKills,
      attackerCasualtiesByType: {},
      defenderCasualtiesByType: {},
      narration: cavAttackerKills + cavDefenderKills > 0
          ? 'Cavalry crashes into the lines!'
          : 'The melee intensifies!',
    ));

    // Melee phase (final)
    final meleeEvents = events.where((e) => e.timestamp >= 40).toList();
    final meleeAttackerKills = meleeEvents
        .where((e) => e.eventType == CombatEventType.kill && (e.attackerId?.startsWith('atk_') ?? false))
        .length;
    final meleeDefenderKills = meleeEvents
        .where((e) => e.eventType == CombatEventType.kill && (e.attackerId?.startsWith('def_') ?? false))
        .length;

    phases.add(PhaseResult(
      phase: CombatPhase.melee,
      attackerLuckRoll: 50 + _random.nextInt(50),
      defenderLuckRoll: 50 + _random.nextInt(50),
      attackerLuckModifier: 1.0,
      defenderLuckModifier: 1.0,
      attackerKills: meleeAttackerKills,
      defenderKills: meleeDefenderKills,
      attackerCasualtiesByType: {},
      defenderCasualtiesByType: {},
      narration: 'Fierce melee combat!',
    ));

    return phases;
  }

  /// Create legacy BattleRound objects for compatibility.
  List<BattleRound> _createLegacyRounds(List<PhaseResult> phases) {
    return phases
        .map((p) => BattleRound(
              attackerRolls: [p.attackerLuckRoll],
              defenderRolls: [p.defenderLuckRoll],
              attackerBonus: 0,
              defenderBonus: 0,
              attackerLosses: p.defenderKills,
              defenderLosses: p.attackerKills,
              narration: p.narration,
            ))
        .toList();
  }
}
