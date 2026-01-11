import 'dart:math';
import '../data/map/game_map.dart';
import '../data/models/unit.dart';
import '../data/models/unit_type.dart';
import '../data/models/village.dart';
import '../data/models/combat_log.dart';

/// 2D position on the battlefield.
class BattlePosition {
  double x; // 0-100 (width)
  double y; // 0-60 (depth)

  BattlePosition(this.x, this.y);

  double distanceTo(BattlePosition other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return sqrt(dx * dx + dy * dy);
  }

  BattlePosition copy() => BattlePosition(x, y);
}

/// Combat unit state during battle - tracks individual soldier.
class CombatUnit {
  final String id;
  final Unit unit;
  final bool isAttacker;
  final bool isGarrison;

  // Combat state
  int hp;
  double attackCooldown;
  BattlePosition position;
  bool isDead = false;

  // Ranged state
  int ammo;

  // Cavalry state
  int currentCharge; // Decays while in melee
  double timeInMelee; // Seconds spent in melee (for charge decay)
  double timeOutOfMelee; // Seconds since last melee (for charge reset)
  bool hasCharged = false; // Has the initial charge been applied?

  // Formation modifiers (applied at battle start)
  double defenseModifier = 1.0;
  int rangeModifier = 0;
  double chargeModifier = 1.0;
  double speedModifier = 1.0;
  double attackModifier = 1.0;

  CombatUnit({
    required this.id,
    required this.unit,
    required this.isAttacker,
    this.isGarrison = false,
    required this.position,
  })  : hp = unit.unitType.stats.hp,
        attackCooldown = 0,
        ammo = unit.unitType.baseAmmo,
        currentCharge = unit.unitType.baseCharge,
        timeInMelee = 0,
        timeOutOfMelee = 0;

  UnitType get type => unit.unitType;
  String get category => type.category;
  bool get isRanged => category == 'Ranged';
  bool get isCavalry => category == 'Cavalry';
  bool get isInfantry => category == 'Infantry';
  bool get isAlive => !isDead && hp > 0;
  bool get hasAmmo => ammo > 0;

  /// Effective attack range in battlefield units.
  double get attackRange {
    if (isRanged && hasAmmo) {
      return (type.baseRange + rangeModifier).toDouble();
    }
    return 1.0; // Melee range
  }

  /// Movement speed (battlefield units per second).
  double get moveSpeed => type.baseSpeed * speedModifier;

  /// Attack interval in seconds.
  double get attackInterval {
    if (isRanged && hasAmmo) {
      return type.baseFireRate;
    }
    return 1.0; // 1 second melee interval
  }

  /// Get effective attack stat.
  int get effectiveAttack {
    final base = type.stats.attack + unit.bonusAttack;
    return (base * attackModifier).round();
  }

  /// Get effective defense stat.
  int get effectiveDefense {
    final base = type.stats.defense + unit.bonusDefense;
    return (base * defenseModifier).round();
  }

  /// Get effective missile stat.
  int get effectiveMissile => type.baseMissile + unit.bonusAttack;

  /// Get effective charge bonus.
  int get effectiveCharge => (currentCharge * chargeModifier).round();
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
  final BattlePosition? position; // For visual effects

  CombatEvent({
    required this.timestamp,
    required this.eventType,
    this.attackerId,
    this.targetId,
    this.damage = 0,
    this.isCrit = false,
    this.message,
    this.position,
  });
}

enum CombatEventType {
  attack,
  rangedAttack,
  kill,
  charge,
  volley,
  meleeClash,
  victory,
  defeat,
}

/// Battlefield constants.
class Battlefield {
  static const double width = 100.0;
  static const double height = 60.0;
  static const double attackerSpawnMinY = 0.0;
  static const double attackerSpawnMaxY = 30.0;
  static const double defenderSpawnMinY = 70.0;
  static const double defenderSpawnMaxY = 100.0;
}

/// Phase 2 tick-based continuous combat engine.
/// No morale, no routing - fight to the death.
class CombatEngine {
  final Random _random = Random();

  /// Simulation tick rate (seconds per tick).
  static const double tickRate = 0.1;

  /// Maximum battle duration (seconds) - extended for larger battles.
  static const double maxBattleDuration = 120.0;

  /// Defender bonus constants.
  static const double baseDefenderBonus = 0.10; // +10% defense

  /// Numbers advantage bonus: disabled for balance.
  /// Having more units is already an advantage without damage multipliers.
  double _numbersAdvantageMultiplier(int myCount, int enemyCount) {
    return 1.0;
  }

  /// Fortress modifiers for defenders.
  double _fortressDefenseBonus(int level) => switch (level) {
        1 => 0.15,
        2 => 0.30,
        >= 3 => 0.50,
        _ => 0.0,
      };

  int _fortressRangeBonus(int level) => switch (level) {
        1 => 1,
        2 => 1,
        >= 3 => 2,
        _ => 0,
      };

  double _fortressCavalryPenalty(int level) => switch (level) {
        1 => 0.80, // -20%
        2 => 0.60, // -40%
        >= 3 => 0.40, // -60%
        _ => 1.0,
      };

  /// Simplified battle simulation for testing.
  /// Wraps resolveCombat with test-friendly parameter names.
  BattleRecord simulateBattle({
    required List<Unit> attackerUnits,
    required List<Unit> defenderUnits,
    required BattleFormation attackerFormation,
    required BattleFormation defenderFormation,
    required String attackerName,
    required String defenderName,
    required String attackerId,
    required String defenderId,
    required String attackerOwnerId,
    required String defenderOwnerId,
    required GameMap gameMap,
    int defenderFortressLevel = 0,
  }) {
    return resolveCombat(
      attackerName: attackerName,
      defenderName: defenderName,
      attackerId: attackerId,
      defenderId: defenderId,
      attackerOwnerId: attackerOwnerId,
      defenderOwnerId: defenderOwnerId,
      attackers: attackerUnits,
      defenders: defenderUnits,
      map: gameMap,
      attackerFormation: attackerFormation,
      defenderFormation: defenderFormation,
      defenderFortressLevel: defenderFortressLevel,
    );
  }

  /// Main combat resolution - Phase 2 continuous tick-based simulation.
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
    BattleFormation attackerFormation = BattleFormation.shieldWall,
    BattleFormation defenderFormation = BattleFormation.shieldWall,
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

    // Create combat units with 2D positions
    final attackerUnits = _createUnits(
      attackers,
      isAttacker: true,
      formation: attackerFormation,
      garrisonCount: 0,
    );

    final defenderUnits = _createUnits(
      defenders,
      isAttacker: false,
      formation: defenderFormation,
      garrisonCount: garrisonCount,
    );

    // Apply formation modifiers
    _applyFormationModifiers(attackerUnits, attackerFormation);
    _applyFormationModifiers(defenderUnits, defenderFormation);

    // Apply defender bonuses
    _applyDefenderBonuses(defenderUnits, defenderFortressLevel);

    // Formation effectiveness modifier
    final formationMod = attackerFormation.bonusAgainst(defenderFormation);
    final defenderFormationMod = defenderFormation.bonusAgainst(attackerFormation);

    // Enemy formation modifiers (affects incoming damage)
    final enemyChargeModForAttacker = defenderFormation.modifiers.enemyChargeMultiplier;
    final enemyChargeModForDefender = attackerFormation.modifiers.enemyChargeMultiplier;

    // Fortress cavalry penalty for attackers
    final fortressCavPenalty = _fortressCavalryPenalty(defenderFortressLevel);

    // Simulation state
    double currentTime = 0;
    bool battleEnded = false;
    bool attackerWon = false;

    // Initial charge event if cavalry present
    if (attackerUnits.any((u) => u.isCavalry) || defenderUnits.any((u) => u.isCavalry)) {
      events.add(CombatEvent(
        timestamp: 0,
        eventType: CombatEventType.charge,
        message: 'Cavalry prepares to charge!',
      ));
    }

    // Main simulation loop - fight to the death
    while (!battleEnded && currentTime < maxBattleDuration) {
      currentTime += tickRate;

      final aliveAttackers = attackerUnits.where((u) => u.isAlive).toList();
      final aliveDefenders = defenderUnits.where((u) => u.isAlive).toList();

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
      for (final unit in aliveAttackers) {
        _processUnitTick(
          unit: unit,
          enemies: aliveDefenders,
          allies: aliveAttackers,
          events: events,
          currentTime: currentTime,
          formationMod: formationMod,
          enemyChargeMod: enemyChargeModForDefender,
          cavalryPenalty: fortressCavPenalty,
          isAttacker: true,
        );
      }

      // Process each defender unit
      for (final unit in aliveDefenders) {
        _processUnitTick(
          unit: unit,
          enemies: aliveAttackers,
          allies: aliveDefenders,
          events: events,
          currentTime: currentTime,
          formationMod: defenderFormationMod,
          enemyChargeMod: enemyChargeModForAttacker,
          cavalryPenalty: 1.0, // Defenders don't have fortress penalty
          isAttacker: false,
        );
      }

      // Move units toward enemies
      _moveUnits(aliveAttackers, aliveDefenders, tickRate);
      _moveUnits(aliveDefenders, aliveAttackers, tickRate);

      // Update charge decay/reset for cavalry
      _updateChargeState(aliveAttackers, aliveDefenders, tickRate);
      _updateChargeState(aliveDefenders, aliveAttackers, tickRate);
    }

    // Determine final outcome if battle timed out
    if (!battleEnded) {
      final remainingAttackers = attackerUnits.where((u) => u.isAlive).length;
      final remainingDefenders = defenderUnits.where((u) => u.isAlive).length;
      attackerWon = remainingAttackers > remainingDefenders;
    }

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

  /// Create combat units with initial positions based on formation.
  List<CombatUnit> _createUnits(
    List<Unit> units, {
    required bool isAttacker,
    required BattleFormation formation,
    required int garrisonCount,
  }) {
    final combatUnits = <CombatUnit>[];
    final garrisonStartIndex = units.length - garrisonCount;

    // Sort units by category for formation positioning
    final infantry = <int>[];
    final ranged = <int>[];
    final cavalry = <int>[];

    for (int i = 0; i < units.length; i++) {
      switch (units[i].unitType.category) {
        case 'Infantry':
          infantry.add(i);
        case 'Ranged':
          ranged.add(i);
        case 'Cavalry':
          cavalry.add(i);
      }
    }

    // Position units based on formation
    final positions = _getFormationPositions(
      formation: formation,
      isAttacker: isAttacker,
      infantryCount: infantry.length,
      rangedCount: ranged.length,
      cavalryCount: cavalry.length,
    );

    int posIndex = 0;

    // Place infantry
    for (final i in infantry) {
      combatUnits.add(CombatUnit(
        id: '${isAttacker ? "atk" : "def"}_$i',
        unit: units[i],
        isAttacker: isAttacker,
        isGarrison: i >= garrisonStartIndex,
        position: positions[posIndex++],
      ));
    }

    // Place ranged
    for (final i in ranged) {
      combatUnits.add(CombatUnit(
        id: '${isAttacker ? "atk" : "def"}_$i',
        unit: units[i],
        isAttacker: isAttacker,
        isGarrison: i >= garrisonStartIndex,
        position: positions[posIndex++],
      ));
    }

    // Place cavalry
    for (final i in cavalry) {
      combatUnits.add(CombatUnit(
        id: '${isAttacker ? "atk" : "def"}_$i',
        unit: units[i],
        isAttacker: isAttacker,
        isGarrison: i >= garrisonStartIndex,
        position: positions[posIndex++],
      ));
    }

    return combatUnits;
  }

  /// Get formation positions for units.
  /// Returns positions in order: [infantry positions], [ranged positions], [cavalry positions]
  /// to match the order in _createUnits.
  List<BattlePosition> _getFormationPositions({
    required BattleFormation formation,
    required bool isAttacker,
    required int infantryCount,
    required int rangedCount,
    required int cavalryCount,
  }) {
    final infantryPositions = <BattlePosition>[];
    final rangedPositions = <BattlePosition>[];
    final cavalryPositions = <BattlePosition>[];

    final totalCount = infantryCount + rangedCount + cavalryCount;
    if (totalCount == 0) return [];

    // Spawn positions - attackers at bottom, defenders at top
    final baseY = isAttacker ? 15.0 : 45.0;
    final direction = isAttacker ? 1.0 : -1.0;

    switch (formation) {
      case BattleFormation.shieldWall:
        // Infantry in front line, ranged behind, cavalry on flanks
        for (int i = 0; i < infantryCount; i++) {
          final x = 50.0 + (i - infantryCount / 2) * 3;
          infantryPositions.add(BattlePosition(x.clamp(10, 90), baseY));
        }
        for (int i = 0; i < rangedCount; i++) {
          final x = 50.0 + (i - rangedCount / 2) * 4;
          rangedPositions.add(BattlePosition(x.clamp(10, 90), baseY - direction * 8));
        }
        for (int i = 0; i < cavalryCount; i++) {
          final side = i % 2 == 0 ? -1 : 1;
          final offset = (i ~/ 2) * 3;
          final x = 50.0 + side * (35 + offset);
          cavalryPositions.add(BattlePosition(x.clamp(5, 95), baseY + direction * 3));
        }

      case BattleFormation.crescent:
        // Cavalry in front on wings, infantry in middle, ranged at back
        for (int i = 0; i < infantryCount; i++) {
          final x = 50.0 + (i - infantryCount / 2) * 3;
          infantryPositions.add(BattlePosition(x.clamp(20, 80), baseY));
        }
        for (int i = 0; i < rangedCount; i++) {
          final x = 50.0 + (i - rangedCount / 2) * 4;
          rangedPositions.add(BattlePosition(x.clamp(20, 80), baseY - direction * 10));
        }
        final lightCav = cavalryCount ~/ 2;
        for (int i = 0; i < lightCav; i++) {
          final x = 15.0 + i * 4;
          cavalryPositions.add(BattlePosition(x, baseY + direction * 10));
        }
        for (int i = lightCav; i < cavalryCount; i++) {
          final x = 85.0 - (i - lightCav) * 4;
          cavalryPositions.add(BattlePosition(x, baseY + direction * 10));
        }

      case BattleFormation.skirmish:
        // Ranged in front, infantry scattered middle, cavalry at back
        for (int i = 0; i < infantryCount; i++) {
          final x = 25.0 + (i * 50.0 / max(1, infantryCount - 1));
          infantryPositions.add(BattlePosition(x.clamp(15, 85), baseY - direction * 3));
        }
        for (int i = 0; i < rangedCount; i++) {
          final x = 20.0 + (i * 60.0 / max(1, rangedCount - 1));
          rangedPositions.add(BattlePosition(x.clamp(10, 90), baseY + direction * 5));
        }
        for (int i = 0; i < cavalryCount; i++) {
          final x = 30.0 + (i * 40.0 / max(1, cavalryCount - 1));
          cavalryPositions.add(BattlePosition(x.clamp(20, 80), baseY - direction * 10));
        }
    }

    // Return in order: infantry, ranged, cavalry (matching _createUnits order)
    return [...infantryPositions, ...rangedPositions, ...cavalryPositions];
  }

  /// Apply formation-specific modifiers to units.
  /// Uses additive defense bonuses for predictable stacking.
  void _applyFormationModifiers(List<CombatUnit> units, BattleFormation formation) {
    final mods = formation.modifiers;

    for (final unit in units) {
      // Speed modifier applies to all (multiplicative is fine for speed)
      unit.speedModifier *= mods.speedMultiplier;

      // Category-specific modifiers - defense is additive
      if (unit.isInfantry) {
        unit.defenseModifier += mods.infantryDefenseBonus;
      } else if (unit.isRanged) {
        unit.defenseModifier += mods.rangedDefenseBonus;
        unit.rangeModifier += mods.rangedRangeBonus;
      } else if (unit.isCavalry) {
        unit.chargeModifier *= mods.cavalryChargeMultiplier;
      }

      // Melee attack modifier (multiplicative)
      unit.attackModifier *= mods.meleeAttackMultiplier;
    }
  }

  /// Apply defender bonuses (base + fortress).
  /// Uses additive stacking for predictable bonuses.
  void _applyDefenderBonuses(List<CombatUnit> units, int fortressLevel) {
    final fortressDefense = _fortressDefenseBonus(fortressLevel);
    final fortressRange = _fortressRangeBonus(fortressLevel);

    // Total defender bonus is additive: base + fortress
    final totalDefenseBonus = baseDefenderBonus + fortressDefense;

    for (final unit in units) {
      // Apply total defense bonus additively
      unit.defenseModifier += totalDefenseBonus;

      // Fortress range bonus for ranged units
      if (unit.isRanged) {
        unit.rangeModifier += fortressRange;
      }
    }
  }

  /// Process a single unit's tick.
  void _processUnitTick({
    required CombatUnit unit,
    required List<CombatUnit> enemies,
    required List<CombatUnit> allies,
    required List<CombatEvent> events,
    required double currentTime,
    required double formationMod,
    required double enemyChargeMod,
    required double cavalryPenalty,
    required bool isAttacker,
  }) {
    // Reduce cooldown
    unit.attackCooldown = max(0, unit.attackCooldown - tickRate);

    // Can't attack if on cooldown
    if (unit.attackCooldown > 0) return;

    // Find target based on priority
    final target = _findTarget(unit, enemies);
    if (target == null) return;

    // Check range
    final distance = unit.position.distanceTo(target.position);
    if (distance > unit.attackRange) return;

    // Execute attack
    unit.attackCooldown = unit.attackInterval;

    // Determine if this is ranged or melee attack
    final isRangedAttack = unit.isRanged && unit.hasAmmo && distance > 1.5;

    // Calculate damage using Phase 2 formula
    double damage;
    if (isRangedAttack) {
      // Ranged: Missile * (100 / (100 + Defense))
      damage = unit.effectiveMissile * (100.0 / (100.0 + target.effectiveDefense));
      unit.ammo--;

      // Accuracy check
      final accuracy = min(0.90, unit.type.baseAccuracy + unit.unit.bonusAccuracy);
      if (_random.nextDouble() > accuracy) {
        return; // Miss
      }
    } else {
      // Melee: Attack * (100 / (100 + Defense))
      int attackStat = unit.effectiveAttack;

      // Add charge bonus for cavalry on first contact
      if (unit.isCavalry && unit.effectiveCharge > 0 && !unit.hasCharged) {
        attackStat += unit.effectiveCharge;
        unit.hasCharged = true;

        // Apply enemy formation's charge reduction and fortress penalty
        final chargeMultiplier = enemyChargeMod * (isAttacker ? cavalryPenalty : 1.0);
        attackStat = (attackStat * chargeMultiplier).round();
      }

      damage = attackStat * (100.0 / (100.0 + target.effectiveDefense));
    }

    // Apply formation effectiveness modifier
    damage *= formationMod;

    // Apply type counter multiplier
    damage *= unit.type.damageMultiplier(target.type);

    // Random variance ±10%
    damage *= 0.9 + _random.nextDouble() * 0.2;

    // Garrison units are 5% weaker
    if (unit.isGarrison) {
      damage *= 0.95;
    }

    // Numbers advantage: larger armies deal more damage
    final allyCount = allies.where((a) => a.isAlive).length;
    final enemyCount = enemies.where((e) => e.isAlive).length;
    damage *= _numbersAdvantageMultiplier(allyCount, enemyCount);

    // Apply damage
    final finalDamage = max(1, damage.round());
    target.hp -= finalDamage;

    // Record attack event (not every single one to avoid spam)
    if (_random.nextDouble() < 0.3 || target.hp <= 0) {
      events.add(CombatEvent(
        timestamp: currentTime,
        eventType: isRangedAttack ? CombatEventType.rangedAttack : CombatEventType.attack,
        attackerId: unit.id,
        targetId: target.id,
        damage: finalDamage,
        position: target.position.copy(),
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
        position: target.position.copy(),
      ));
    }
  }

  /// Find the best target for a unit based on priority.
  CombatUnit? _findTarget(CombatUnit unit, List<CombatUnit> enemies) {
    final validTargets = enemies.where((e) => e.isAlive).toList();
    if (validTargets.isEmpty) return null;

    // Sort by priority
    final priority = unit.type.targetPriority;

    // Find targets by priority category
    for (final category in priority) {
      final categoryTargets = validTargets.where((e) => e.category == category).toList();
      if (categoryTargets.isNotEmpty) {
        // Return closest in that category
        categoryTargets.sort((a, b) {
          final distA = unit.position.distanceTo(a.position);
          final distB = unit.position.distanceTo(b.position);
          return distA.compareTo(distB);
        });
        return categoryTargets.first;
      }
    }

    // Fallback: closest target
    validTargets.sort((a, b) {
      final distA = unit.position.distanceTo(a.position);
      final distB = unit.position.distanceTo(b.position);
      return distA.compareTo(distB);
    });

    return validTargets.first;
  }

  /// Move units toward their targets.
  void _moveUnits(List<CombatUnit> units, List<CombatUnit> enemies, double dt) {
    for (final unit in units) {
      if (!unit.isAlive) continue;

      final target = _findTarget(unit, enemies);
      if (target == null) continue;

      final distance = unit.position.distanceTo(target.position);

      // Ranged units try to maintain optimal distance
      if (unit.isRanged && unit.hasAmmo) {
        if (distance < 2.0) {
          // Too close, retreat
          final dx = unit.position.x - target.position.x;
          final dy = unit.position.y - target.position.y;
          final len = sqrt(dx * dx + dy * dy);
          if (len > 0) {
            unit.position.x += (dx / len) * unit.moveSpeed * dt;
            unit.position.y += (dy / len) * unit.moveSpeed * dt;
          }
        } else if (distance > unit.attackRange) {
          // Out of range, move closer
          final dx = target.position.x - unit.position.x;
          final dy = target.position.y - unit.position.y;
          final len = sqrt(dx * dx + dy * dy);
          if (len > 0) {
            unit.position.x += (dx / len) * unit.moveSpeed * dt;
            unit.position.y += (dy / len) * unit.moveSpeed * dt;
          }
        }
        // In range, stay put and fire
        continue;
      }

      // Move toward target if not in range
      if (distance > unit.attackRange) {
        final dx = target.position.x - unit.position.x;
        final dy = target.position.y - unit.position.y;
        final len = sqrt(dx * dx + dy * dy);
        if (len > 0) {
          unit.position.x += (dx / len) * unit.moveSpeed * dt;
          unit.position.y += (dy / len) * unit.moveSpeed * dt;
        }
      }

      // Clamp to battlefield
      unit.position.x = unit.position.x.clamp(0, Battlefield.width);
      unit.position.y = unit.position.y.clamp(0, Battlefield.height);
    }
  }

  /// Update cavalry charge state (decay in melee, reset when disengaged).
  void _updateChargeState(List<CombatUnit> units, List<CombatUnit> enemies, double dt) {
    for (final unit in units) {
      if (!unit.isCavalry || !unit.isAlive) continue;

      // Check if in melee
      final inMelee = enemies.any((e) =>
          e.isAlive && unit.position.distanceTo(e.position) <= 1.5);

      if (inMelee) {
        unit.timeInMelee += dt;
        unit.timeOutOfMelee = 0;

        // Charge decays by 1 per second in melee
        if (unit.timeInMelee >= 1.0 && unit.currentCharge > 0) {
          unit.currentCharge--;
          unit.timeInMelee -= 1.0;
        }
      } else {
        unit.timeOutOfMelee += dt;
        unit.timeInMelee = 0;

        // Charge resets after 3 seconds out of melee
        if (unit.timeOutOfMelee >= 3.0) {
          unit.currentCharge = unit.type.baseCharge;
          unit.hasCharged = false;
        }
      }
    }
  }

  /// Create phase summaries from combat events for UI compatibility.
  List<PhaseResult> _createPhasesFromEvents(
    List<CombatEvent> events,
    int initialAttackers,
    int initialDefenders,
  ) {
    final phases = <PhaseResult>[];

    // Ranged phase (first third of battle)
    final rangedEvents = events.where((e) => e.timestamp < 40).toList();
    final rangedAttackerKills = rangedEvents
        .where((e) => e.eventType == CombatEventType.kill && (e.attackerId?.startsWith('atk') ?? false))
        .length;
    final rangedDefenderKills = rangedEvents
        .where((e) => e.eventType == CombatEventType.kill && (e.attackerId?.startsWith('def') ?? false))
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
    final cavalryEvents = events.where((e) => e.timestamp >= 40 && e.timestamp < 80).toList();
    final cavAttackerKills = cavalryEvents
        .where((e) => e.eventType == CombatEventType.kill && (e.attackerId?.startsWith('atk') ?? false))
        .length;
    final cavDefenderKills = cavalryEvents
        .where((e) => e.eventType == CombatEventType.kill && (e.attackerId?.startsWith('def') ?? false))
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
    final meleeEvents = events.where((e) => e.timestamp >= 80).toList();
    final meleeAttackerKills = meleeEvents
        .where((e) => e.eventType == CombatEventType.kill && (e.attackerId?.startsWith('atk') ?? false))
        .length;
    final meleeDefenderKills = meleeEvents
        .where((e) => e.eventType == CombatEventType.kill && (e.attackerId?.startsWith('def') ?? false))
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
