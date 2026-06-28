import 'dart:math';
import 'package:flutter/material.dart';
import '../../../data/models/combat_log.dart';
import '../../../data/models/nationality.dart';
import '../../../data/models/unit_type.dart';
import 'battle_circle.dart';
import 'battlefield_painter.dart';

enum BattlePhase {
  formationSelect, // Player picks formation
  setup, // Initial positioning
  field, // Open-field clash (army vs mobile defenders)
  advance, // Survivors push to the city gate, garrison mans the walls
  cityAssault, // Street fight inside the walls vs the garrison
  flagRaise, // Conqueror lowers the old flag and raises their own
  victory,
  defeat,
}

extension BattleFormationUIExt on BattleFormation {
  String get emoji => switch (this) {
        BattleFormation.crescent => '🐴',
        BattleFormation.shieldWall => '🛡️',
        BattleFormation.skirmish => '🏹',
      };

  String get shortDescription => switch (this) {
        BattleFormation.crescent => 'Cavalry encirclement. Strong vs skirmishers.',
        BattleFormation.shieldWall => 'Tight infantry wall. Strong vs cavalry.',
        BattleFormation.skirmish => 'Spread, mobile harassment. Strong vs shield wall.',
      };
}

// Arrow projectile for ranged attacks
class ArrowProjectile {
  Offset position;
  final Offset start;
  final Offset target;
  final Color color;
  double progress = 0;
  bool hasHit = false;

  ArrowProjectile({
    required this.start,
    required this.target,
    required this.color,
  }) : position = start;

  double get rotation {
    final dx = target.dx - start.dx;
    final dy = target.dy - start.dy;
    return atan2(dy, dx);
  }

  void update(double dt) {
    if (hasHit) return;
    progress += dt * 3.0; // Fast arrows
    if (progress >= 1.0) {
      progress = 1.0;
      hasHit = true;
    }
    // Arc trajectory
    final arcHeight = 60.0;
    final linearPos = Offset.lerp(start, target, progress)!;
    final arc = sin(progress * pi) * arcHeight;
    position = Offset(linearPos.dx, linearPos.dy - arc);
  }
}

class BattleSimulation {
  final BattleRecord record;
  final Nationality attackerNationality;
  final Nationality defenderNationality;
  final Size screenSize;
  final bool isSiege;
  final List<UnitType> attackerUnits;
  final List<UnitType> defenderUnits; // mobile field defenders only
  final List<UnitType> garrisonUnits; // troops behind the walls
  final bool isPlayerAttacker;

  List<BattleCircle> attackerCircles = [];
  List<BattleCircle> defenderCircles = []; // field army
  List<BattleCircle> garrisonCircles = []; // city garrison
  List<BattleCircle> allCircles = [];
  List<AtmosphericParticle> particles = [];
  List<ArrowProjectile> arrows = [];

  // Engine-authoritative per-phase results
  late final BattleEngagement? _fieldEng = record.fieldEngagement;
  late final BattleEngagement? _cityEng = record.cityEngagement;

  // Formations
  BattleFormation? playerFormation;
  BattleFormation? enemyFormation;
  double formationBonus = 1.0;

  BattlePhase phase = BattlePhase.formationSelect;
  double phaseTimer = 0;
  double totalTime = 0;
  double combatTime = 0; // resets each fighting phase
  bool isAutoPlay = true;
  TerrainType terrain = TerrainType.plains;
  double attackerMorale = 1.0;
  double defenderMorale = 1.0;

  // Scene morph + flag-raise progress (0..1), consumed by the painters
  double cityProgress = 0.0;
  double flagRaiseProgress = 0.0;

  final Random _random = Random();
  double _nextArrowTime = 0;

  // Kill bookkeeping (counters drive the header; circles drive the visuals)
  int _attackersKilled = 0;
  int _fieldDefKilled = 0;
  int _garrisonKilled = 0;
  int _phaseAtkApplied = 0;
  int _phaseDefApplied = 0;

  // What the header should show right now
  int _defenderInitialNow = 0;

  Offset clashPoint = Offset.zero;
  Offset _gatePoint = Offset.zero;

  VoidCallback? onPhaseChanged;
  VoidCallback? onBattleEnd;

  BattleSimulation({
    required this.record,
    required this.attackerNationality,
    required this.defenderNationality,
    required this.screenSize,
    this.isSiege = false,
    this.attackerUnits = const [],
    this.defenderUnits = const [],
    this.garrisonUnits = const [],
    this.isPlayerAttacker = true,
  }) {
    terrain = isSiege ? TerrainType.city : _randomTerrain();
    _gatePoint = Offset(screenSize.width * 0.84, (screenSize.height - 150) * 0.5 + 100);
    _initializeParticles();
  }

  bool get hasFieldPhase => _fieldEng != null;
  bool get hasCityPhase => _cityEng != null;
  bool get isFighting => phase == BattlePhase.field || phase == BattlePhase.cityAssault;

  void selectFormation(BattleFormation formation) {
    playerFormation = formation;
    enemyFormation = _pickAIFormation();
    formationBonus = formation.bonusAgainst(enemyFormation!);
    _initializeCircles();
    _transitionTo(BattlePhase.setup);
  }

  BattleFormation _pickAIFormation() {
    if (_random.nextDouble() < 0.30) {
      return BattleFormation.values[_random.nextInt(BattleFormation.values.length)];
    }
    final units = isPlayerAttacker ? _allDefenderTypes : attackerUnits;
    int ranged = 0, cavalry = 0, infantry = 0;
    for (final u in units) {
      switch (u.category) {
        case 'Ranged':
          ranged++;
        case 'Cavalry':
          cavalry++;
        default:
          infantry++;
      }
    }
    if (cavalry >= ranged && cavalry >= infantry) {
      return BattleFormation.crescent;
    } else if (ranged >= infantry) {
      return BattleFormation.skirmish;
    } else {
      return BattleFormation.shieldWall;
    }
  }

  List<UnitType> get _allDefenderTypes => [...defenderUnits, ...garrisonUnits];

  TerrainType _randomTerrain() {
    final types = [TerrainType.plains, TerrainType.hills, TerrainType.forest];
    return types[_random.nextInt(types.length)];
  }

  void _initializeParticles() {
    for (int i = 0; i < 30; i++) {
      particles.add(AtmosphericParticle(
        position: Offset(
          _random.nextDouble() * screenSize.width,
          screenSize.height * 0.4 + _random.nextDouble() * screenSize.height * 0.5,
        ),
        velocity: Offset(20 + _random.nextDouble() * 30, -5 + _random.nextDouble() * 10),
        size: 2 + _random.nextDouble() * 4,
        opacity: 0.1 + _random.nextDouble() * 0.2,
        color: terrain == TerrainType.city ? Colors.grey : Colors.brown.shade300,
      ));
    }
  }

  Rect get _battleArea => Rect.fromLTWH(0, 100, screenSize.width, screenSize.height - 250);

  void _initializeCircles() {
    final battleArea = _battleArea;
    clashPoint = battleArea.center;

    final attackerBaseX = battleArea.left + battleArea.width * 0.12;
    final defenderBaseX = battleArea.right - battleArea.width * 0.12;

    // If there is no field phase (pure city assault), defenders start at the wall.
    final firstDefenders = hasFieldPhase ? defenderUnits : garrisonUnits;
    final firstDefenderList = hasFieldPhase ? defenderCircles : garrisonCircles;

    final totalUnits = attackerUnits.length + firstDefenders.length;
    final circleRadius = totalUnits > 60 ? 12.0 : totalUnits > 40 ? 14.0 : totalUnits > 25 ? 16.0 : 18.0;

    final attackerFormation = isPlayerAttacker ? playerFormation : enemyFormation;
    final defenderFormation = isPlayerAttacker ? enemyFormation : playerFormation;

    _addCircles(attackerUnits, attackerCircles, attackerBaseX, attackerNationality, true, attackerFormation, circleRadius, battleArea);
    _addCircles(firstDefenders, firstDefenderList, defenderBaseX, defenderNationality, false, defenderFormation, circleRadius, battleArea);

    if (hasFieldPhase) {
      _defenderInitialNow = max(firstDefenders.length, _fieldEng?.defenderStart ?? 0);
      cityProgress = 0.0;
    } else {
      _defenderInitialNow = max(firstDefenders.length, _cityEng?.defenderStart ?? 0);
      cityProgress = 1.0; // straight to the walls
    }

    _rebuildAll();
  }

  void _rebuildAll() {
    allCircles = [...attackerCircles, ...defenderCircles, ...garrisonCircles];
  }

  void _addCircles(
    List<UnitType> units,
    List<BattleCircle> circles,
    double baseX,
    Nationality nationality,
    bool isAttacker,
    BattleFormation? formation,
    double circleRadius,
    Rect battleArea,
  ) {
    if (units.isEmpty) return;

    final ranged = units.where((u) => u.category == 'Ranged').toList();
    final cavalry = units.where((u) => u.category == 'Cavalry').toList();
    final infantry = units.where((u) => u.category == 'Infantry').toList();

    switch (formation ?? BattleFormation.shieldWall) {
      case BattleFormation.crescent:
        _positionWedge(cavalry, circles, baseX, battleArea.center.dy, nationality, isAttacker, frontOffset: 80, radius: circleRadius);
        _positionLine(infantry, circles, baseX, battleArea.center.dy, nationality, isAttacker, frontOffset: 0, radius: circleRadius);
        _positionLine(ranged, circles, baseX, battleArea.center.dy, nationality, isAttacker, frontOffset: -70, radius: circleRadius);

      case BattleFormation.shieldWall:
        _positionLine(infantry, circles, baseX, battleArea.center.dy, nationality, isAttacker, frontOffset: 60, tight: true, radius: circleRadius);
        _positionLine(ranged, circles, baseX, battleArea.center.dy, nationality, isAttacker, frontOffset: -30, radius: circleRadius);
        _positionFlanks(cavalry, circles, baseX, battleArea.center.dy, nationality, isAttacker, radius: circleRadius);

      case BattleFormation.skirmish:
        _positionLine(ranged, circles, baseX, battleArea.center.dy, nationality, isAttacker, frontOffset: 60, spread: 1.3, radius: circleRadius);
        _positionFlanks(cavalry, circles, baseX, battleArea.center.dy, nationality, isAttacker, radius: circleRadius);
        _positionLine(infantry, circles, baseX, battleArea.center.dy, nationality, isAttacker, frontOffset: -50, radius: circleRadius);
    }
  }

  void _positionLine(
    List<UnitType> units,
    List<BattleCircle> circles,
    double baseX,
    double centerY,
    Nationality nationality,
    bool isAttacker, {
    double frontOffset = 0,
    bool tight = false,
    double spread = 1.0,
    double radius = 9.0,
  }) {
    if (units.isEmpty) return;

    final xOffset = isAttacker ? frontOffset : -frontOffset;
    final maxHeight = screenSize.height * 0.5;

    final baseSpacing = tight ? 22.0 : 28.0;
    final unitsPerRow = max(1, (maxHeight / baseSpacing).floor());
    final numRows = (units.length / unitsPerRow).ceil();
    final rowSpacing = 35.0;

    final actualUnitsPerRow = (units.length / numRows).ceil();
    final ySpacing = min(baseSpacing, maxHeight / actualUnitsPerRow) * spread;

    for (int i = 0; i < units.length; i++) {
      final row = i ~/ actualUnitsPerRow;
      final col = i % actualUnitsPerRow;
      final unitsInThisRow = min(actualUnitsPerRow, units.length - row * actualUnitsPerRow);

      final rowXOffset = row * rowSpacing * (isAttacker ? -1 : 1);
      final y = centerY + (col - unitsInThisRow / 2) * ySpacing;

      circles.add(BattleCircle(
        position: Offset(baseX + xOffset + rowXOffset, y),
        factionId: nationality.id,
        color: nationality.color,
        assetPath: nationality.assetPath,
        unitType: units[i],
        baseRadiusOverride: radius,
      ));
    }
  }

  void _positionWedge(
    List<UnitType> units,
    List<BattleCircle> circles,
    double baseX,
    double centerY,
    Nationality nationality,
    bool isAttacker, {
    double frontOffset = 0,
    double radius = 9.0,
  }) {
    if (units.isEmpty) return;

    final xOffset = isAttacker ? frontOffset : -frontOffset;
    final baseRowSpacing = max(20.0, min(30.0, 300.0 / units.length));
    final baseYSpacing = max(18.0, min(28.0, (screenSize.height * 0.4) / (units.length / 2 + 1)));

    for (int i = 0; i < units.length; i++) {
      final row = i ~/ 2;
      final side = i.isEven ? -1 : 1;
      final x = baseX + xOffset - row * baseRowSpacing * (isAttacker ? 1 : -1);
      final y = centerY + side * (row + 1) * baseYSpacing;
      circles.add(BattleCircle(
        position: Offset(x, y),
        factionId: nationality.id,
        color: nationality.color,
        assetPath: nationality.assetPath,
        unitType: units[i],
        baseRadiusOverride: radius,
      ));
    }
  }

  void _positionFlanks(
    List<UnitType> units,
    List<BattleCircle> circles,
    double baseX,
    double centerY,
    Nationality nationality,
    bool isAttacker, {
    double radius = 9.0,
  }) {
    if (units.isEmpty) return;

    final maxHeight = screenSize.height * 0.35;
    final unitsPerFlank = (units.length / 2).ceil();
    final flankSpacing = max(12.0, min(22.0, maxHeight / (unitsPerFlank + 1)));

    for (int i = 0; i < units.length; i++) {
      final isTopFlank = i.isEven;
      final indexInFlank = i ~/ 2;
      final flankY = isTopFlank ? -(80 + indexInFlank * flankSpacing) : (80 + indexInFlank * flankSpacing);

      circles.add(BattleCircle(
        position: Offset(baseX + indexInFlank * 18 * (isAttacker ? -1 : 1), centerY + flankY),
        factionId: nationality.id,
        color: nationality.color,
        assetPath: nationality.assetPath,
        unitType: units[i],
        baseRadiusOverride: radius,
      ));
    }
  }

  Rect get battleBounds => Rect.fromLTWH(20, 120, screenSize.width - 40, screenSize.height - 300);

  // Active defenders for the current phase
  List<BattleCircle> get _activeDefenders =>
      (phase == BattlePhase.cityAssault || phase == BattlePhase.flagRaise) ? garrisonCircles : defenderCircles;

  Offset _findEngagementTarget(BattleCircle unit, List<BattleCircle> enemies) {
    final aliveEnemies = enemies.where((e) => e.isAlive && !e.isDying && !e.isRouting).toList();
    if (aliveEnemies.isEmpty) {
      // No enemies in reach — push toward the gate during the assault.
      return phase == BattlePhase.advance ? _gatePoint : clashPoint;
    }

    BattleCircle? bestTarget;
    double bestScore = double.infinity;
    for (final enemy in aliveEnemies) {
      final dx = (enemy.position.dx - unit.position.dx).abs();
      final dy = (enemy.position.dy - unit.position.dy).abs();
      final score = dx + dy * 2.0;
      if (score < bestScore) {
        bestScore = score;
        bestTarget = enemy;
      }
    }
    if (bestTarget != null) {
      final midX = (unit.position.dx + bestTarget.position.dx) / 2;
      return Offset(midX, bestTarget.position.dy);
    }
    return clashPoint;
  }

  // Header / morale getters
  int get aliveAttackers => attackerCircles.where((c) => c.isAlive && !c.isDying && !c.isRouting).length;
  int get aliveDefenders => _activeDefenders.where((c) => c.isAlive && !c.isDying && !c.isRouting).length;
  int get combatEffectiveAttackers => attackerCircles.where((c) => c.isAlive && !c.isDying).length;
  int get combatEffectiveDefenders => _activeDefenders.where((c) => c.isAlive && !c.isDying).length;
  int get defenderInitialNow => _defenderInitialNow;
  int get routingAttackers => attackerCircles.where((c) => c.isRouting).length;
  int get routingDefenders => _activeDefenders.where((c) => c.isRouting).length;

  void update(double dt) {
    phaseTimer += dt;
    totalTime += dt;

    for (final p in particles) {
      p.update(dt, screenSize);
    }
    for (final arrow in arrows) {
      arrow.update(dt);
    }
    arrows.removeWhere((a) => a.hasHit && a.progress >= 1.2);

    final isEngaging = isFighting;
    final defenders = _activeDefenders;

    for (final c in attackerCircles) {
      final target = phase == BattlePhase.advance
          ? _gatePoint
          : _findEngagementTarget(c, defenders);
      c.update(dt, battleBounds, allCircles, target,
          isAttacker: true, isEngaging: isEngaging || phase == BattlePhase.advance, isRegrouping: false);
    }
    for (final c in defenderCircles) {
      final target = _findEngagementTarget(c, attackerCircles);
      c.update(dt, battleBounds, allCircles, target, isAttacker: false, isEngaging: phase == BattlePhase.field, isRegrouping: false);
    }
    for (final c in garrisonCircles) {
      final target = _findEngagementTarget(c, attackerCircles);
      c.update(dt, battleBounds, allCircles, target, isAttacker: false, isEngaging: phase == BattlePhase.cityAssault, isRegrouping: false);
    }

    _updateMorale();

    switch (phase) {
      case BattlePhase.formationSelect:
        break;

      case BattlePhase.setup:
        if (phaseTimer > 1.0) {
          _transitionTo(hasFieldPhase ? BattlePhase.field : BattlePhase.cityAssault);
        }
        break;

      case BattlePhase.field:
        final fEng = _fieldEng;
        if (fEng == null) {
          _finishFieldPhase();
          break;
        }
        combatTime += dt;
        _processCombat(dt, attackerCircles, defenderCircles,
            atkTarget: fEng.attackerLosses, defTarget: fEng.defenderLosses);
        if (_phaseDone(fEng) || combatTime > 22) {
          _finishFieldPhase();
        }
        break;

      case BattlePhase.advance:
        cityProgress = (cityProgress + dt * 1.4).clamp(0.0, 1.0);
        // Defender survivors flee the field
        for (final c in defenderCircles.where((c) => c.isAlive && !c.isDying && !c.isRouting)) {
          c.route();
        }
        if (phaseTimer > 1.3) {
          _beginCityAssault();
        }
        break;

      case BattlePhase.cityAssault:
        final cEng = _cityEng;
        if (cEng == null) {
          _finishCityPhase();
          break;
        }
        combatTime += dt;
        _processCombat(dt, attackerCircles, garrisonCircles,
            atkTarget: cEng.attackerLosses, defTarget: cEng.defenderLosses);
        if (_phaseDone(cEng) || combatTime > 22) {
          _finishCityPhase();
        }
        break;

      case BattlePhase.flagRaise:
        flagRaiseProgress = (flagRaiseProgress + dt * 0.45).clamp(0.0, 1.0);
        if (flagRaiseProgress >= 1.0 && phaseTimer > 0.6) {
          _transitionTo(record.attackerWon ? BattlePhase.victory : BattlePhase.defeat);
          onBattleEnd?.call();
        }
        break;

      case BattlePhase.victory:
      case BattlePhase.defeat:
        break;
    }
  }

  bool _phaseDone(BattleEngagement eng) =>
      _phaseAtkApplied >= eng.attackerLosses && _phaseDefApplied >= eng.defenderLosses;

  void _processCombat(double dt, List<BattleCircle> attackers, List<BattleCircle> defenders,
      {required int atkTarget, required int defTarget}) {
    // Arrows
    if (totalTime >= _nextArrowTime) {
      _spawnArrows(attackers, defenders);
      _nextArrowTime = totalTime + 0.3 + _random.nextDouble() * 0.4;
    }

    // Pace casualties over the phase; front-line units fall first.
    const battleDuration = 11.0;
    final progress = min(1.0, combatTime / battleDuration);
    final expectedAtk = (atkTarget * progress).floor();
    final expectedDef = (defTarget * progress).floor();

    while (_phaseDefApplied < expectedDef) {
      final victim = _pickFrontline(defenders, attackers);
      if (victim == null) break;
      victim.die();
      _phaseDefApplied++;
      _registerDefenderKill();
    }
    while (_phaseAtkApplied < expectedAtk) {
      final victim = _pickFrontline(attackers, defenders);
      if (victim == null) break;
      victim.die();
      _phaseAtkApplied++;
      _attackersKilled++;
    }
  }

  void _registerDefenderKill() {
    if (phase == BattlePhase.field) {
      _fieldDefKilled++;
    } else {
      _garrisonKilled++;
    }
  }

  // Pick the alive unit closest to the enemy line — the front rank dies first,
  // ranged units in the rear survive longest. This is what makes the fight read
  // as real combat instead of random culling.
  BattleCircle? _pickFrontline(List<BattleCircle> pool, List<BattleCircle> enemies) {
    final alive = pool.where((c) => c.isAlive && !c.isDying && !c.isRouting).toList();
    if (alive.isEmpty) return null;
    final liveEnemies = enemies.where((c) => c.isAlive && !c.isDying).toList();
    if (liveEnemies.isEmpty) {
      return alive[_random.nextInt(alive.length)];
    }

    BattleCircle? best;
    double bestScore = double.infinity;
    for (final c in alive) {
      double nearest = double.infinity;
      for (final e in liveEnemies) {
        final d = (c.position - e.position).distanceSquared;
        if (d < nearest) nearest = d;
      }
      // Ranged units cling to the back; bias against killing them early.
      final score = nearest * (c.isRanged ? 2.4 : 1.0);
      if (score < bestScore) {
        bestScore = score;
        best = c;
      }
    }
    return best;
  }

  void _spawnArrows(List<BattleCircle> attackers, List<BattleCircle> defenders) {
    void volley(List<BattleCircle> shooters, List<BattleCircle> targets, Color color) {
      final archers = shooters.where((c) => c.isAlive && !c.isDying && c.isRanged).toList();
      final live = targets.where((c) => c.isAlive && !c.isDying).toList();
      if (live.isEmpty) return;
      for (final archer in archers) {
        if (_random.nextDouble() < 0.6) {
          final t = live[_random.nextInt(live.length)];
          arrows.add(ArrowProjectile(
            start: archer.position,
            target: t.position + Offset(_random.nextDouble() * 30 - 15, _random.nextDouble() * 30 - 15),
            color: color,
          ));
        }
      }
    }

    volley(attackers, defenders, attackerNationality.color);
    volley(defenders, attackers, defenderNationality.color);
  }

  void _transitionTo(BattlePhase newPhase) {
    phase = newPhase;
    phaseTimer = 0;
    onPhaseChanged?.call();
  }

  void _finishFieldPhase() {
    final eng = _fieldEng;
    // Make sure the field tally is exactly the engine's result.
    if (eng != null) {
      _forceKills(defenderCircles, eng.defenderLosses - _phaseDefApplied, isDefender: true);
      _forceKills(attackerCircles, eng.attackerLosses - _phaseAtkApplied, isDefender: false);
    }

    if (eng != null && (!eng.attackerWon || aliveAttackers <= 0)) {
      // Attack broke on the field — no city assault.
      _transitionTo(BattlePhase.defeat);
      onBattleEnd?.call();
      return;
    }
    if (!hasCityPhase) {
      _transitionTo(record.attackerWon ? BattlePhase.victory : BattlePhase.defeat);
      onBattleEnd?.call();
      return;
    }
    combatTime = 0;
    _phaseAtkApplied = 0;
    _phaseDefApplied = 0;
    _transitionTo(BattlePhase.advance);
  }

  void _beginCityAssault() {
    cityProgress = 1.0;
    _spawnGarrison();
    _defenderInitialNow = _cityEng?.defenderStart ?? garrisonUnits.length;
    combatTime = 0;
    _transitionTo(BattlePhase.cityAssault);
  }

  void _finishCityPhase() {
    final eng = _cityEng;
    if (eng != null) {
      _forceKills(garrisonCircles, eng.defenderLosses - _phaseDefApplied, isDefender: true);
      _forceKills(attackerCircles, eng.attackerLosses - _phaseAtkApplied, isDefender: false);
    }

    if (eng == null || eng.attackerWon) {
      // City taken — raise the conqueror's flag over the gate.
      _transitionTo(BattlePhase.flagRaise);
    } else {
      _transitionTo(BattlePhase.defeat);
      onBattleEnd?.call();
    }
  }

  void _forceKills(List<BattleCircle> pool, int count, {required bool isDefender}) {
    for (int i = 0; i < count; i++) {
      final victim = _pickFrontline(pool, isDefender ? attackerCircles : _activeDefenders);
      if (victim == null) break;
      victim.die();
      if (isDefender) {
        _phaseDefApplied++;
        _registerDefenderKill();
      } else {
        _phaseAtkApplied++;
        _attackersKilled++;
      }
    }
  }

  void _spawnGarrison() {
    final battleArea = _battleArea;
    final defenderFormation = isPlayerAttacker ? enemyFormation : playerFormation;
    final baseX = battleArea.right - battleArea.width * 0.10;
    final radius = garrisonUnits.length > 40 ? 13.0 : garrisonUnits.length > 25 ? 15.0 : 17.0;
    garrisonCircles.clear();
    _addCircles(garrisonUnits, garrisonCircles, baseX, defenderNationality, false, defenderFormation, radius, battleArea);
    _rebuildAll();
  }

  void _updateMorale() {
    final atkInit = max(1, record.initialAttackerCount);
    final atkLossRatio = (_attackersKilled / atkInit).clamp(0.0, 1.0);
    attackerMorale = (1 - atkLossRatio * 0.8).clamp(0.0, 1.0);

    final defInit = max(1, _defenderInitialNow);
    final defAlive = combatEffectiveDefenders;
    final defLossRatio = (1 - defAlive / defInit).clamp(0.0, 1.0);
    defenderMorale = (1 - defLossRatio * 0.8).clamp(0.0, 1.0);

    for (final c in attackerCircles.where((c) => c.isAlive && !c.isRouting)) {
      c.morale = attackerMorale;
    }
    for (final c in _activeDefenders.where((c) => c.isAlive && !c.isRouting)) {
      c.morale = defenderMorale;
    }
  }

  void skipToEnd() {
    // Fast-forward whatever phase we're in to the engine's final state.
    int guard = 0;
    while (phase != BattlePhase.victory && phase != BattlePhase.defeat && guard++ < 64) {
      switch (phase) {
        case BattlePhase.formationSelect:
          return; // need a formation first
        case BattlePhase.setup:
          _transitionTo(hasFieldPhase ? BattlePhase.field : BattlePhase.cityAssault);
        case BattlePhase.field:
          _finishFieldPhase();
        case BattlePhase.advance:
          _beginCityAssault();
        case BattlePhase.cityAssault:
          _finishCityPhase();
        case BattlePhase.flagRaise:
          flagRaiseProgress = 1.0;
          _transitionTo(record.attackerWon ? BattlePhase.victory : BattlePhase.defeat);
          onBattleEnd?.call();
        case BattlePhase.victory:
        case BattlePhase.defeat:
          break;
      }
    }
  }

  void setAutoPlay(bool auto) {
    isAutoPlay = auto;
  }

  // Legacy getters for UI compatibility
  int get currentRound => (totalTime / 3).floor();
  int get attackerLossesThisRound => _fieldDefKilled + _garrisonKilled;
  int get defenderLossesThisRound => _attackersKilled;
  bool get diceRolled => isFighting;
}
