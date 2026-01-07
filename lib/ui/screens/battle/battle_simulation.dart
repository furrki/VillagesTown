import 'dart:math';
import 'package:flutter/material.dart';
import '../../../data/models/combat_log.dart';
import '../../../data/models/nationality.dart';
import '../../../data/models/unit_type.dart';
import 'battle_circle.dart';
import 'battlefield_painter.dart';

enum BattlePhase {
  formationSelect, // New: player picks formation
  setup,
  rangedVolley,
  cavalryCharge,
  meleeClash,
  rolling,
  resolution,
  regroup,
  victory,
  defeat,
}

// BattleFormation is now imported from combat_log.dart
// Uses: crescent (cavalry), romanFormation (infantry), guerilla (ranged)

extension BattleFormationUIExt on BattleFormation {
  String get emoji => switch (this) {
    BattleFormation.crescent => '🐴',
    BattleFormation.romanFormation => '🛡️',
    BattleFormation.guerilla => '🏹',
  };

  String get shortDescription => switch (this) {
    BattleFormation.crescent => 'Cavalry leads the charge. Strong vs archers.',
    BattleFormation.romanFormation => 'Infantry forms a wall. Strong vs cavalry.',
    BattleFormation.guerilla => 'Hit-and-run tactics. Strong vs infantry.',
  };
}

// Arrow projectile for ranged phase
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
    progress += dt * 2.5; // ~0.4s flight - slightly slower for visibility
    if (progress >= 1.0) {
      progress = 1.0;
      hasHit = true;
    }
    // Arc trajectory - higher arc for more dramatic effect
    final arcHeight = 80.0;
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
  double formationBonus = 1.0; // Applied to player's side

  BattlePhase phase = BattlePhase.formationSelect;
  double phaseTimer = 0;
  double totalTime = 0;
  int currentRound = 0;
  bool isAutoPlay = true; // Auto-play by default for faster battles
  TerrainType terrain = TerrainType.plains;
  double attackerMorale = 1.0;
  double defenderMorale = 1.0;

  // Current round state
  List<BattleCircle> attackersAtStake = [];
  List<BattleCircle> defendersAtStake = [];
  List<int> attackerDice = [];
  List<int> defenderDice = [];
  int attackerLossesThisRound = 0;
  int defenderLossesThisRound = 0;

  // Animation state
  double diceRollProgress = 0;
  bool diceRolled = false;
  Offset clashPoint = Offset.zero;
  bool _arrowsSpawned = false;
  bool _cavalryCharged = false;

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
    // Don't initialize circles until formation is selected
    _initializeParticles();
  }

  /// Called after player selects formation
  void selectFormation(BattleFormation formation) {
    playerFormation = formation;
    // AI picks formation based on their army composition
    enemyFormation = _pickAIFormation();
    // Calculate bonus
    formationBonus = formation.bonusAgainst(enemyFormation!);
    // Now initialize circles with formation-based positioning
    _initializeCircles();
    _transitionTo(BattlePhase.setup);
  }

  BattleFormation _pickAIFormation() {
    final units = isPlayerAttacker ? defenderUnits : attackerUnits;

    // Count unit categories
    int ranged = 0, cavalry = 0, infantry = 0;
    for (final u in units) {
      switch (u.category) {
        case 'Ranged': ranged++;
        case 'Cavalry': cavalry++;
        default: infantry++;
      }
    }

    // Pick formation based on strongest unit type
    if (cavalry >= ranged && cavalry >= infantry) {
      return BattleFormation.crescent;
    } else if (ranged >= infantry) {
      return BattleFormation.guerilla;
    } else {
      return BattleFormation.romanFormation;
    }
  }

  TerrainType _randomTerrain() {
    final random = Random();
    final types = [TerrainType.plains, TerrainType.hills, TerrainType.forest];
    return types[random.nextInt(types.length)];
  }

  void _initializeParticles() {
    final random = Random();
    // Dust/smoke particles
    for (int i = 0; i < 30; i++) {
      particles.add(AtmosphericParticle(
        position: Offset(
          random.nextDouble() * screenSize.width,
          screenSize.height * 0.4 + random.nextDouble() * screenSize.height * 0.5,
        ),
        velocity: Offset(20 + random.nextDouble() * 30, -5 + random.nextDouble() * 10),
        size: 2 + random.nextDouble() * 4,
        opacity: 0.1 + random.nextDouble() * 0.2,
        color: terrain == TerrainType.city ? Colors.grey : Colors.brown.shade300,
      ));
    }
  }

  void _initializeCircles() {
    final random = Random();
    final battleArea = Rect.fromLTWH(0, 100, screenSize.width, screenSize.height - 250);
    clashPoint = battleArea.center;

    // Spread armies further apart for more visible movement
    final attackerBaseX = battleArea.left + battleArea.width * 0.12;
    final defenderBaseX = battleArea.right - battleArea.width * 0.12;

    // Scale circle radius based on total units (smaller circles for larger battles)
    final totalUnits = attackerUnits.length + defenderUnits.length;
    final circleRadius = totalUnits > 60 ? 6.0 : totalUnits > 40 ? 7.0 : totalUnits > 25 ? 8.0 : 9.0;

    // Determine formations for each side
    final attackerFormation = isPlayerAttacker ? playerFormation : enemyFormation;
    final defenderFormation = isPlayerAttacker ? enemyFormation : playerFormation;

    // Helper to create circles with formation-based positioning
    void addCircles(List<UnitType> units, List<BattleCircle> circles,
        double baseX, Nationality nationality, bool isAttacker, BattleFormation? formation) {
      // If no unit types provided, create generic militia
      if (units.isEmpty) {
        final count = isAttacker ? record.initialAttackerCount : record.initialDefenderCount;
        for (int i = 0; i < count; i++) {
          final offset = Offset(
            (random.nextDouble() - 0.5) * 60,
            (random.nextDouble() - 0.5) * 100,
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

      // Group units by category
      final ranged = units.where((u) => u.category == 'Ranged').toList();
      final cavalry = units.where((u) => u.category == 'Cavalry').toList();
      final infantry = units.where((u) => u.category == 'Infantry').toList();

      // Formation-specific positioning - wider separations for visibility
      switch (formation ?? BattleFormation.romanFormation) {
        case BattleFormation.crescent:
          // Cavalry in front wedge, infantry behind, archers far back
          _positionWedge(cavalry, circles, baseX, battleArea.center.dy, nationality, isAttacker, frontOffset: 80, radius: circleRadius);
          _positionLine(infantry, circles, baseX, battleArea.center.dy, nationality, isAttacker, frontOffset: 0, radius: circleRadius);
          _positionLine(ranged, circles, baseX, battleArea.center.dy, nationality, isAttacker, frontOffset: -70, radius: circleRadius);

        case BattleFormation.romanFormation:
          // Infantry front wall, archers behind, cavalry on flanks
          _positionLine(infantry, circles, baseX, battleArea.center.dy, nationality, isAttacker, frontOffset: 60, tight: true, radius: circleRadius);
          _positionLine(ranged, circles, baseX, battleArea.center.dy, nationality, isAttacker, frontOffset: -30, radius: circleRadius);
          _positionFlanks(cavalry, circles, baseX, battleArea.center.dy, nationality, isAttacker, radius: circleRadius);

        case BattleFormation.guerilla:
          // Archers front spread, cavalry flanks ready, infantry rear guard
          _positionLine(ranged, circles, baseX, battleArea.center.dy, nationality, isAttacker, frontOffset: 60, spread: 1.3, radius: circleRadius);
          _positionFlanks(cavalry, circles, baseX, battleArea.center.dy, nationality, isAttacker, radius: circleRadius);
          _positionLine(infantry, circles, baseX, battleArea.center.dy, nationality, isAttacker, frontOffset: -50, radius: circleRadius);
      }
    }

    addCircles(attackerUnits, attackerCircles, attackerBaseX, attackerNationality, true, attackerFormation);
    addCircles(defenderUnits, defenderCircles, defenderBaseX, defenderNationality, false, defenderFormation);

    allCircles = [...attackerCircles, ...defenderCircles];
  }

  void _positionLine(List<UnitType> units, List<BattleCircle> circles,
      double baseX, double centerY, Nationality nationality, bool isAttacker,
      {double frontOffset = 0, bool tight = false, double spread = 1.0, double radius = 9.0}) {
    if (units.isEmpty) return;

    final xOffset = isAttacker ? frontOffset : -frontOffset;
    final maxHeight = screenSize.height * 0.5; // Use half screen height max

    // Calculate rows needed to fit all units
    final baseSpacing = tight ? 22.0 : 28.0;
    final unitsPerRow = max(1, (maxHeight / baseSpacing).floor());
    final numRows = (units.length / unitsPerRow).ceil();
    final rowSpacing = 35.0;

    // Adjust spacing to fit units
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

  void _positionWedge(List<UnitType> units, List<BattleCircle> circles,
      double baseX, double centerY, Nationality nationality, bool isAttacker,
      {double frontOffset = 0, double radius = 9.0}) {
    if (units.isEmpty) return;

    final xOffset = isAttacker ? frontOffset : -frontOffset;
    final maxHeight = screenSize.height * 0.4;

    // Scale spacing based on unit count
    final baseRowSpacing = max(20.0, min(30.0, 300.0 / units.length));
    final baseYSpacing = max(18.0, min(28.0, maxHeight / (units.length / 2 + 1)));

    for (int i = 0; i < units.length; i++) {
      // Wedge: leader in front, others staggered behind
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

  void _positionFlanks(List<UnitType> units, List<BattleCircle> circles,
      double baseX, double centerY, Nationality nationality, bool isAttacker, {double radius = 9.0}) {
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

  /// Find the best engagement target for a unit
  /// Prefers enemies in similar Y position (same "lane"), weighted by distance
  Offset _findEngagementTarget(BattleCircle unit, List<BattleCircle> enemies) {
    final aliveEnemies = enemies.where((e) => e.isAlive && !e.isDying && !e.isRouting).toList();
    if (aliveEnemies.isEmpty) {
      // No enemies left, move toward center
      return clashPoint;
    }

    // Find nearest enemy with Y-position weighting
    // Units prefer to engage enemies at similar Y (horizontal clash lines)
    BattleCircle? bestTarget;
    double bestScore = double.infinity;

    for (final enemy in aliveEnemies) {
      final dx = (enemy.position.dx - unit.position.dx).abs();
      final dy = (enemy.position.dy - unit.position.dy).abs();
      // Score: prioritize Y alignment (multiply dy by 2 to penalize vertical distance)
      final score = dx + dy * 2.0;
      if (score < bestScore) {
        bestScore = score;
        bestTarget = enemy;
      }
    }

    if (bestTarget != null) {
      // Target point is between unit and enemy (engagement zone)
      final midX = (unit.position.dx + bestTarget.position.dx) / 2;
      return Offset(midX, bestTarget.position.dy);
    }

    return clashPoint;
  }

  // Combat-effective units (for battle calculations - excludes dead only)
  int get combatEffectiveAttackers => attackerCircles.where((c) => c.isAlive && !c.isDying).length;
  int get combatEffectiveDefenders => defenderCircles.where((c) => c.isAlive && !c.isDying).length;

  // Display counts (for UI - excludes routing for visual clarity)
  int get aliveAttackers => attackerCircles.where((c) => c.isAlive && !c.isDying && !c.isRouting).length;
  int get aliveDefenders => defenderCircles.where((c) => c.isAlive && !c.isDying && !c.isRouting).length;
  int get routingAttackers => attackerCircles.where((c) => c.isRouting).length;
  int get routingDefenders => defenderCircles.where((c) => c.isRouting).length;

  void update(double dt) {
    phaseTimer += dt;
    totalTime += dt;

    // Update atmospheric particles
    for (final p in particles) {
      p.update(dt, screenSize);
    }

    // Update arrows
    for (final arrow in arrows) {
      arrow.update(dt);
    }
    arrows.removeWhere((a) => a.hasHit && a.progress >= 1.2);

    // Determine phase state for units
    final isEngaging = phase == BattlePhase.cavalryCharge ||
        phase == BattlePhase.meleeClash ||
        phase == BattlePhase.rolling ||
        phase == BattlePhase.resolution;
    final isRegrouping = phase == BattlePhase.regroup;

    // Update all circles with phase-appropriate behavior
    // Each unit targets nearest enemy in their "lane" (similar Y position)
    for (final c in attackerCircles) {
      final target = _findEngagementTarget(c, defenderCircles);
      c.update(dt, battleBounds, allCircles, target,
          isAttacker: true, isEngaging: isEngaging, isRegrouping: isRegrouping);
    }
    for (final c in defenderCircles) {
      final target = _findEngagementTarget(c, attackerCircles);
      c.update(dt, battleBounds, allCircles, target,
          isAttacker: false, isEngaging: isEngaging, isRegrouping: isRegrouping);
    }

    // Update army morale based on losses
    _updateMorale();

    // Phase-specific logic
    switch (phase) {
      case BattlePhase.formationSelect:
        // Wait for player to select formation
        break;

      case BattlePhase.setup:
        // PREPARE: Armies face each other, hold formation
        if (phaseTimer > 1.0) {
          _prepareRound();
          _transitionTo(BattlePhase.rangedVolley);
        }
        break;

      case BattlePhase.rangedVolley:
        // Archers fire while armies hold position
        if (!_arrowsSpawned) {
          _spawnArrowVolley();
          _arrowsSpawned = true;
        }
        if (phaseTimer > 1.2) {
          _transitionTo(BattlePhase.cavalryCharge);
        }
        break;

      case BattlePhase.cavalryCharge:
        // ADVANCE: Cavalry leads the charge
        if (!_cavalryCharged) {
          _triggerCavalryCharge();
          _cavalryCharged = true;
        }
        if (phaseTimer > 1.0) {
          _transitionTo(BattlePhase.meleeClash);
        }
        break;

      case BattlePhase.meleeClash:
        // ENGAGE: All units clash at center
        if (phaseTimer > 1.2) {
          rollDice();
        }
        break;

      case BattlePhase.rolling:
        diceRollProgress += dt * 4.0;
        if (diceRollProgress >= 1.0) {
          diceRollProgress = 1.0;
          _transitionTo(BattlePhase.resolution);
        }
        break;

      case BattlePhase.resolution:
        // Apply casualties
        if (phaseTimer > 0.3 && !_deathsApplied) {
          _applyDeaths();
        }
        if (phaseTimer > 0.8) {
          _transitionTo(BattlePhase.regroup);
        }
        break;

      case BattlePhase.regroup:
        // WITHDRAW: Armies pull back to regroup
        // Clear stake markers
        for (final c in allCircles) {
          c.isAtStake = false;
        }
        // Give time for units to return to positions
        if (phaseTimer > 1.0) {
          _checkRouting();
        }
        if (phaseTimer > 1.5) {
          _checkBattleEnd();
        }
        break;

      case BattlePhase.victory:
      case BattlePhase.defeat:
        // End state - wait for user
        break;
    }
  }

  void _spawnArrowVolley() {
    final random = Random();

    // Attacker archers fire at defender targets
    final attackerArchers = attackerCircles.where((c) => c.isAlive && c.isRanged).toList();
    final defenderTargets = defenderCircles.where((c) => c.isAlive).toList();

    for (final archer in attackerArchers) {
      if (defenderTargets.isEmpty) continue;
      // Target cavalry first (vulnerable to arrows), then others
      final cavalryTargets = defenderTargets.where((c) => c.isCavalry).toList();
      final target = cavalryTargets.isNotEmpty
          ? cavalryTargets[random.nextInt(cavalryTargets.length)]
          : defenderTargets[random.nextInt(defenderTargets.length)];

      arrows.add(ArrowProjectile(
        start: archer.position,
        target: target.position + Offset(random.nextDouble() * 20 - 10, random.nextDouble() * 20 - 10),
        color: attackerNationality.color,
      ));
    }

    // Defender archers fire at attacker targets
    final defenderArchers = defenderCircles.where((c) => c.isAlive && c.isRanged).toList();
    final attackerTargets = attackerCircles.where((c) => c.isAlive).toList();

    for (final archer in defenderArchers) {
      if (attackerTargets.isEmpty) continue;
      final cavalryTargets = attackerTargets.where((c) => c.isCavalry).toList();
      final target = cavalryTargets.isNotEmpty
          ? cavalryTargets[random.nextInt(cavalryTargets.length)]
          : attackerTargets[random.nextInt(attackerTargets.length)];

      arrows.add(ArrowProjectile(
        start: archer.position,
        target: target.position + Offset(random.nextDouble() * 20 - 10, random.nextDouble() * 20 - 10),
        color: defenderNationality.color,
      ));
    }
  }

  void _triggerCavalryCharge() {
    // Give cavalry a big speed boost for dramatic charge
    for (final c in attackerCircles.where((c) => c.isAlive && c.isCavalry)) {
      c.velocity += const Offset(400, 0);
    }
    for (final c in defenderCircles.where((c) => c.isAlive && c.isCavalry)) {
      c.velocity += const Offset(-400, 0);
    }
  }

  bool _deathsApplied = false;

  void _transitionTo(BattlePhase newPhase) {
    phase = newPhase;
    phaseTimer = 0;
    _deathsApplied = false;

    if (newPhase == BattlePhase.rangedVolley) {
      _arrowsSpawned = false;
      _cavalryCharged = false;
      diceRolled = false;
      diceRollProgress = 0;
      _routingCheckedThisRound = false; // Reset for new round
    }

    onPhaseChanged?.call();
  }

  void _prepareRound() {
    // Select circles at stake
    final aliveAttackersList = attackerCircles.where((c) => c.isAlive && !c.isDying).toList();
    final aliveDefendersList = defenderCircles.where((c) => c.isAlive && !c.isDying).toList();

    final attackerStakeCount = min(3, aliveAttackersList.length);
    final defenderStakeCount = min(2, aliveDefendersList.length);

    attackersAtStake = aliveAttackersList.take(attackerStakeCount).toList();
    defendersAtStake = aliveDefendersList.take(defenderStakeCount).toList();

    for (final c in attackersAtStake) {
      c.isAtStake = true;
    }
    for (final c in defendersAtStake) {
      c.isAtStake = true;
    }

    // Get dice values from record, or generate if not available
    if (currentRound < record.rounds.length) {
      final round = record.rounds[currentRound];
      attackerDice = round.attackerRolls;
      defenderDice = round.defenderRolls;
      attackerLossesThisRound = round.attackerLosses;
      defenderLossesThisRound = round.defenderLosses;
    } else {
      // Generate fallback dice if record is exhausted
      final random = Random();
      final numDice = max(1, min(attackerStakeCount, defenderStakeCount));
      attackerDice = List.generate(numDice, (_) => random.nextInt(6) + 1);
      defenderDice = List.generate(numDice, (_) => random.nextInt(6) + 1);

      // Calculate losses based on dice comparison
      int attackerWins = 0;
      final sorted1 = List<int>.from(attackerDice)..sort((a, b) => b.compareTo(a));
      final sorted2 = List<int>.from(defenderDice)..sort((a, b) => b.compareTo(a));
      for (int i = 0; i < min(sorted1.length, sorted2.length); i++) {
        if (sorted1[i] > sorted2[i]) attackerWins++;
      }
      attackerLossesThisRound = numDice - attackerWins;
      defenderLossesThisRound = attackerWins;
    }
  }

  void rollDice() {
    if (phase != BattlePhase.meleeClash || diceRolled) return;
    diceRolled = true;
    diceRollProgress = 0;
    _transitionTo(BattlePhase.rolling);
  }

  void _applyDeaths() {
    _deathsApplied = true;
    final random = Random();

    // Kill attacker circles - randomly select from all alive attackers
    int attackerDeaths = attackerLossesThisRound;
    final aliveAttackersList = attackerCircles.where((c) => c.isAlive && !c.isDying).toList();
    aliveAttackersList.shuffle(random);
    for (final c in aliveAttackersList) {
      if (attackerDeaths <= 0) break;
      c.die();
      attackerDeaths--;
    }

    // Kill defender circles - randomly select from all alive defenders
    int defenderDeaths = defenderLossesThisRound;
    final aliveDefendersList = defenderCircles.where((c) => c.isAlive && !c.isDying).toList();
    aliveDefendersList.shuffle(random);
    for (final c in aliveDefendersList) {
      if (defenderDeaths <= 0) break;
      c.die();
      defenderDeaths--;
    }

    currentRound++;
  }

  void _checkBattleEnd() {
    // Use combat-effective (includes routing) to check for elimination
    final attackersLeft = combatEffectiveAttackers;
    final defendersLeft = combatEffectiveDefenders;

    // Check for elimination
    final eliminated = attackersLeft <= 0 || defendersLeft <= 0;

    // Check if we've played enough rounds (at least until record rounds are done)
    final recordRoundsDone = currentRound >= record.rounds.length;
    final minRoundsPlayed = currentRound >= 3; // At least 3 rounds for visual effect

    // End battle if eliminated, or if record rounds done and visual minimum met
    if (eliminated || (recordRoundsDone && minRoundsPlayed)) {
      // USE THE RECORD'S PREDETERMINED OUTCOME
      if (record.attackerWon) {
        // Kill remaining defenders to match outcome
        for (final c in defenderCircles.where((c) => c.isAlive && !c.isDying)) {
          c.die();
        }
        _transitionTo(BattlePhase.victory);
      } else {
        // Kill remaining attackers to match outcome
        for (final c in attackerCircles.where((c) => c.isAlive && !c.isDying)) {
          c.die();
        }
        _transitionTo(BattlePhase.defeat);
      }
      onBattleEnd?.call();
    } else if (currentRound > 15) {
      // Safety cap - force end with record outcome
      if (record.attackerWon) {
        _transitionTo(BattlePhase.victory);
      } else {
        _transitionTo(BattlePhase.defeat);
      }
      onBattleEnd?.call();
    } else {
      // Continue to next round
      _prepareRound();
      _transitionTo(BattlePhase.rangedVolley);
    }
  }

  void _updateMorale() {
    // Calculate morale based on losses (use combat-effective to prevent cascade)
    final attackerLossRatio = 1 - (combatEffectiveAttackers / max(1, record.initialAttackerCount));
    final defenderLossRatio = 1 - (combatEffectiveDefenders / max(1, record.initialDefenderCount));

    // Morale drops with losses
    attackerMorale = (1 - attackerLossRatio * 0.8).clamp(0.0, 1.0);
    defenderMorale = (1 - defenderLossRatio * 0.8).clamp(0.0, 1.0);

    // Apply morale to circles (visual only - NO routing here)
    for (final c in attackerCircles.where((c) => c.isAlive && !c.isRouting)) {
      c.morale = attackerMorale;
    }
    for (final c in defenderCircles.where((c) => c.isAlive && !c.isRouting)) {
      c.morale = defenderMorale;
    }
  }

  // Called once per round in regroup phase
  bool _routingCheckedThisRound = false;

  void _checkRouting() {
    if (_routingCheckedThisRound) return;
    _routingCheckedThisRound = true;

    final random = Random();

    // Only check routing at very low morale, once per round
    if (attackerMorale < 0.2) {
      for (final c in attackerCircles.where((c) => c.isAlive && !c.isRouting && !c.isDying)) {
        // 20% base chance at morale 0, scaling down
        if (random.nextDouble() < (0.2 - attackerMorale)) {
          c.route();
        }
      }
    }

    if (defenderMorale < 0.2) {
      for (final c in defenderCircles.where((c) => c.isAlive && !c.isRouting && !c.isDying)) {
        if (random.nextDouble() < (0.2 - defenderMorale)) {
          c.route();
        }
      }
    }
  }

  void skipToEnd() {
    // Apply all recorded rounds
    while (currentRound < record.rounds.length) {
      _prepareRound();
      _applyDeaths();
    }

    // USE THE RECORD'S PREDETERMINED OUTCOME
    if (record.attackerWon) {
      // Kill remaining defenders
      for (final c in defenderCircles.where((c) => c.isAlive)) {
        c.die();
      }
      _transitionTo(BattlePhase.victory);
    } else {
      // Kill remaining attackers
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
}
