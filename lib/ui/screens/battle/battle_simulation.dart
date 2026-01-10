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
  combat, // Continuous combat
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
  final List<UnitType> defenderUnits;
  final bool isPlayerAttacker;

  List<BattleCircle> attackerCircles = [];
  List<BattleCircle> defenderCircles = [];
  List<BattleCircle> allCircles = [];
  List<AtmosphericParticle> particles = [];
  List<ArrowProjectile> arrows = [];

  // Formations
  BattleFormation? playerFormation;
  BattleFormation? enemyFormation;
  double formationBonus = 1.0;

  BattlePhase phase = BattlePhase.formationSelect;
  double phaseTimer = 0;
  double totalTime = 0;
  bool isAutoPlay = true;
  TerrainType terrain = TerrainType.plains;
  double attackerMorale = 1.0;
  double defenderMorale = 1.0;

  // Continuous combat state
  final Random _random = Random();
  double _nextArrowTime = 0;
  int _attackerKillsApplied = 0;
  int _defenderKillsApplied = 0;
  int _totalAttackerKills = 0;
  int _totalDefenderKills = 0;

  // Animation state
  Offset clashPoint = Offset.zero;

  // Callbacks
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
    this.isPlayerAttacker = true,
  }) {
    terrain = isSiege ? TerrainType.city : _randomTerrain();
    _initializeParticles();
    // Calculate total kills from record for pacing
    _totalAttackerKills = record.phases.fold(0, (sum, p) => sum + p.attackerKills);
    _totalDefenderKills = record.phases.fold(0, (sum, p) => sum + p.defenderKills);
  }

  void selectFormation(BattleFormation formation) {
    playerFormation = formation;
    enemyFormation = _pickAIFormation();
    formationBonus = formation.bonusAgainst(enemyFormation!);
    _initializeCircles();
    _transitionTo(BattlePhase.setup);
  }

  BattleFormation _pickAIFormation() {
    // 30% chance to pick random formation (less predictable)
    if (_random.nextDouble() < 0.30) {
      return BattleFormation.values[_random.nextInt(BattleFormation.values.length)];
    }

    // 70% chance to pick based on army composition
    final units = isPlayerAttacker ? defenderUnits : attackerUnits;
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

  void _initializeCircles() {
    final battleArea = Rect.fromLTWH(0, 100, screenSize.width, screenSize.height - 250);
    clashPoint = battleArea.center;

    final attackerBaseX = battleArea.left + battleArea.width * 0.12;
    final defenderBaseX = battleArea.right - battleArea.width * 0.12;

    final totalUnits = attackerUnits.length + defenderUnits.length;
    final circleRadius = totalUnits > 60 ? 12.0 : totalUnits > 40 ? 14.0 : totalUnits > 25 ? 16.0 : 18.0;

    final attackerFormation = isPlayerAttacker ? playerFormation : enemyFormation;
    final defenderFormation = isPlayerAttacker ? enemyFormation : playerFormation;

    _addCircles(attackerUnits, attackerCircles, attackerBaseX, attackerNationality, true, attackerFormation, circleRadius, battleArea);
    _addCircles(defenderUnits, defenderCircles, defenderBaseX, defenderNationality, false, defenderFormation, circleRadius, battleArea);

    allCircles = [...attackerCircles, ...defenderCircles];
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
    if (units.isEmpty) {
      final count = isAttacker ? record.initialAttackerCount : record.initialDefenderCount;
      for (int i = 0; i < count; i++) {
        final offset = Offset(
          (_random.nextDouble() - 0.5) * 60,
          (_random.nextDouble() - 0.5) * 100,
        );
        circles.add(BattleCircle(
          position: Offset(baseX, battleArea.center.dy) + offset,
          factionId: nationality.id,
          color: nationality.color,
          assetPath: nationality.assetPath,
          unitType: UnitType.militia,
          baseRadiusOverride: circleRadius,
        ));
      }
      return;
    }

    final ranged = units.where((u) => u.category == 'Ranged').toList();
    final cavalry = units.where((u) => u.category == 'Cavalry').toList();
    final infantry = units.where((u) => u.category == 'Infantry').toList();

    switch (formation ?? BattleFormation.shieldWall) {
      case BattleFormation.crescent:
        // Cavalry in front on wings, infantry behind, ranged at back
        _positionWedge(cavalry, circles, baseX, battleArea.center.dy, nationality, isAttacker, frontOffset: 80, radius: circleRadius);
        _positionLine(infantry, circles, baseX, battleArea.center.dy, nationality, isAttacker, frontOffset: 0, radius: circleRadius);
        _positionLine(ranged, circles, baseX, battleArea.center.dy, nationality, isAttacker, frontOffset: -70, radius: circleRadius);

      case BattleFormation.shieldWall:
        // Infantry in tight front line, ranged behind, cavalry on flanks
        _positionLine(infantry, circles, baseX, battleArea.center.dy, nationality, isAttacker, frontOffset: 60, tight: true, radius: circleRadius);
        _positionLine(ranged, circles, baseX, battleArea.center.dy, nationality, isAttacker, frontOffset: -30, radius: circleRadius);
        _positionFlanks(cavalry, circles, baseX, battleArea.center.dy, nationality, isAttacker, radius: circleRadius);

      case BattleFormation.skirmish:
        // Spread out - ranged in front, infantry scattered, cavalry ready
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

  Offset _findEngagementTarget(BattleCircle unit, List<BattleCircle> enemies) {
    final aliveEnemies = enemies.where((e) => e.isAlive && !e.isDying && !e.isRouting).toList();
    if (aliveEnemies.isEmpty) {
      return clashPoint;
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

  int get combatEffectiveAttackers => attackerCircles.where((c) => c.isAlive && !c.isDying).length;
  int get combatEffectiveDefenders => defenderCircles.where((c) => c.isAlive && !c.isDying).length;
  int get aliveAttackers => attackerCircles.where((c) => c.isAlive && !c.isDying && !c.isRouting).length;
  int get aliveDefenders => defenderCircles.where((c) => c.isAlive && !c.isDying && !c.isRouting).length;
  int get routingAttackers => attackerCircles.where((c) => c.isRouting).length;
  int get routingDefenders => defenderCircles.where((c) => c.isRouting).length;

  void update(double dt) {
    phaseTimer += dt;
    totalTime += dt;

    // Update particles
    for (final p in particles) {
      p.update(dt, screenSize);
    }

    // Update arrows
    for (final arrow in arrows) {
      arrow.update(dt);
    }
    arrows.removeWhere((a) => a.hasHit && a.progress >= 1.2);

    // Unit updates
    final isEngaging = phase == BattlePhase.combat;

    for (final c in attackerCircles) {
      final target = _findEngagementTarget(c, defenderCircles);
      c.update(dt, battleBounds, allCircles, target, isAttacker: true, isEngaging: isEngaging, isRegrouping: false);
    }
    for (final c in defenderCircles) {
      final target = _findEngagementTarget(c, attackerCircles);
      c.update(dt, battleBounds, allCircles, target, isAttacker: false, isEngaging: isEngaging, isRegrouping: false);
    }

    _updateMorale();

    switch (phase) {
      case BattlePhase.formationSelect:
        break;

      case BattlePhase.setup:
        if (phaseTimer > 1.0) {
          _transitionTo(BattlePhase.combat);
        }
        break;

      case BattlePhase.combat:
        _processContinuousCombat(dt);
        _checkBattleEnd();
        break;

      case BattlePhase.victory:
      case BattlePhase.defeat:
        break;
    }
  }

  void _processContinuousCombat(double dt) {
    // Spawn arrows continuously from alive archers
    if (totalTime >= _nextArrowTime) {
      _spawnArrowsFromArchers();
      _nextArrowTime = totalTime + 0.3 + _random.nextDouble() * 0.4; // Every 0.3-0.7s
    }

    // Apply casualties continuously based on time
    // Pace kills over ~8-15 seconds of combat
    final battleDuration = 12.0;
    final expectedAttackerKillsNow = (_totalAttackerKills * min(1.0, totalTime / battleDuration)).floor();
    final expectedDefenderKillsNow = (_totalDefenderKills * min(1.0, totalTime / battleDuration)).floor();

    // Apply attacker kills (kill defenders)
    while (_attackerKillsApplied < expectedAttackerKillsNow) {
      final target = _pickRandomAlive(defenderCircles);
      if (target != null) {
        target.die();
        _attackerKillsApplied++;
      } else {
        break;
      }
    }

    // Apply defender kills (kill attackers)
    while (_defenderKillsApplied < expectedDefenderKillsNow) {
      final target = _pickRandomAlive(attackerCircles);
      if (target != null) {
        target.die();
        _defenderKillsApplied++;
      } else {
        break;
      }
    }

    // Check routing at low morale
    if (attackerMorale < 0.2 && _random.nextDouble() < dt * 0.5) {
      final target = _pickRandomAlive(attackerCircles);
      if (target != null && !target.isRouting) {
        target.route();
      }
    }
    if (defenderMorale < 0.2 && _random.nextDouble() < dt * 0.5) {
      final target = _pickRandomAlive(defenderCircles);
      if (target != null && !target.isRouting) {
        target.route();
      }
    }
  }

  BattleCircle? _pickRandomAlive(List<BattleCircle> circles) {
    final alive = circles.where((c) => c.isAlive && !c.isDying && !c.isRouting).toList();
    if (alive.isEmpty) return null;
    return alive[_random.nextInt(alive.length)];
  }

  void _spawnArrowsFromArchers() {
    // Attacker archers fire
    final attackerArchers = attackerCircles.where((c) => c.isAlive && !c.isDying && c.isRanged).toList();
    final defenderTargets = defenderCircles.where((c) => c.isAlive && !c.isDying).toList();

    // Only some archers fire each volley for more natural look
    for (final archer in attackerArchers) {
      if (_random.nextDouble() < 0.6 && defenderTargets.isNotEmpty) {
        final target = defenderTargets[_random.nextInt(defenderTargets.length)];
        arrows.add(ArrowProjectile(
          start: archer.position,
          target: target.position + Offset(_random.nextDouble() * 30 - 15, _random.nextDouble() * 30 - 15),
          color: attackerNationality.color,
        ));
      }
    }

    // Defender archers fire
    final defenderArchers = defenderCircles.where((c) => c.isAlive && !c.isDying && c.isRanged).toList();
    final attackerTargets = attackerCircles.where((c) => c.isAlive && !c.isDying).toList();

    for (final archer in defenderArchers) {
      if (_random.nextDouble() < 0.6 && attackerTargets.isNotEmpty) {
        final target = attackerTargets[_random.nextInt(attackerTargets.length)];
        arrows.add(ArrowProjectile(
          start: archer.position,
          target: target.position + Offset(_random.nextDouble() * 30 - 15, _random.nextDouble() * 30 - 15),
          color: defenderNationality.color,
        ));
      }
    }
  }

  void _transitionTo(BattlePhase newPhase) {
    phase = newPhase;
    phaseTimer = 0;
    onPhaseChanged?.call();
  }

  void _checkBattleEnd() {
    final attackersLeft = combatEffectiveAttackers;
    final defendersLeft = combatEffectiveDefenders;

    // All casualties applied and one side eliminated
    final allKillsApplied = _attackerKillsApplied >= _totalAttackerKills && _defenderKillsApplied >= _totalDefenderKills;
    final oneEliminated = attackersLeft <= 0 || defendersLeft <= 0;

    if (allKillsApplied || oneEliminated || totalTime > 20) {
      // Use record's predetermined outcome
      if (record.attackerWon) {
        for (final c in defenderCircles.where((c) => c.isAlive && !c.isDying)) {
          c.die();
        }
        _transitionTo(BattlePhase.victory);
      } else {
        for (final c in attackerCircles.where((c) => c.isAlive && !c.isDying)) {
          c.die();
        }
        _transitionTo(BattlePhase.defeat);
      }
      onBattleEnd?.call();
    }
  }

  void _updateMorale() {
    final attackerLossRatio = 1 - (combatEffectiveAttackers / max(1, record.initialAttackerCount));
    final defenderLossRatio = 1 - (combatEffectiveDefenders / max(1, record.initialDefenderCount));

    attackerMorale = (1 - attackerLossRatio * 0.8).clamp(0.0, 1.0);
    defenderMorale = (1 - defenderLossRatio * 0.8).clamp(0.0, 1.0);

    for (final c in attackerCircles.where((c) => c.isAlive && !c.isRouting)) {
      c.morale = attackerMorale;
    }
    for (final c in defenderCircles.where((c) => c.isAlive && !c.isRouting)) {
      c.morale = defenderMorale;
    }
  }

  void skipToEnd() {
    // Apply all remaining kills
    while (_attackerKillsApplied < _totalAttackerKills) {
      final target = _pickRandomAlive(defenderCircles);
      if (target != null) {
        target.die();
        _attackerKillsApplied++;
      } else {
        break;
      }
    }
    while (_defenderKillsApplied < _totalDefenderKills) {
      final target = _pickRandomAlive(attackerCircles);
      if (target != null) {
        target.die();
        _defenderKillsApplied++;
      } else {
        break;
      }
    }

    if (record.attackerWon) {
      for (final c in defenderCircles.where((c) => c.isAlive)) {
        c.die();
      }
      _transitionTo(BattlePhase.victory);
    } else {
      for (final c in attackerCircles.where((c) => c.isAlive)) {
        c.die();
      }
      _transitionTo(BattlePhase.defeat);
    }
    onBattleEnd?.call();
  }

  void setAutoPlay(bool auto) {
    isAutoPlay = auto;
  }

  // Legacy getters for UI compatibility
  List<int> get attackerDice => [_random.nextInt(6) + 1];
  List<int> get defenderDice => [_random.nextInt(6) + 1];
  int get currentRound => (totalTime / 3).floor();
  int get attackerLossesThisRound => _defenderKillsApplied;
  int get defenderLossesThisRound => _attackerKillsApplied;
  double get diceRollProgress => 1.0;
  bool get diceRolled => phase == BattlePhase.combat;
}
