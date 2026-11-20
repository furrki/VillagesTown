import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villages_town/data/models/combat_log.dart';
import 'package:villages_town/data/models/nationality.dart';
import 'package:villages_town/ui/screens/battle/battle_circle.dart';
import 'package:villages_town/ui/screens/battle/battle_simulation.dart';

class TrackedCircle extends BattleCircle {
  TrackedCircle(Offset position, {this.step = Offset.zero})
    : super(position: position, factionId: 'test', color: Colors.red);

  final Offset step;
  late Offset selectedTarget;

  TrackedCircle copy() => TrackedCircle(position, step: step)
    ..isAlive = isAlive
    ..isDying = isDying
    ..isRouting = isRouting
    ..routeDirection = routeDirection
    ..deathProgress = deathProgress
    ..velocity = velocity;

  @override
  void update(
    double dt,
    Rect bounds,
    List<BattleCircle> others,
    Offset targetCenter, {
    bool isAttacker = true,
    bool isEngaging = false,
    bool isRegrouping = false,
  }) {
    selectedTarget = targetCenter;
    if (isAlive && !isDying && !isRouting) {
      position += step;
    } else {
      super.update(dt, bounds, others, targetCenter, isAttacker: isAttacker);
    }
  }
}

class CountedCircles extends ListBase<BattleCircle> {
  CountedCircles(this.circles);

  final List<BattleCircle> circles;
  int filterCalls = 0;

  @override
  Iterable<BattleCircle> where(bool Function(BattleCircle) test) {
    filterCalls++;
    return circles.where(test);
  }

  @override
  int get length => circles.length;
  @override
  set length(int value) => circles.length = value;
  @override
  BattleCircle operator [](int index) => circles[index];
  @override
  void operator []=(int index, BattleCircle value) => circles[index] = value;
}

Offset previousTarget(
  BattleCircle unit,
  List<TrackedCircle> enemies,
  Offset fallback,
) {
  final eligible = enemies
      .where((enemy) => enemy.isAlive && !enemy.isDying && !enemy.isRouting)
      .toList();
  TrackedCircle? best;
  double bestScore = double.infinity;
  for (final enemy in eligible) {
    final dx = (enemy.position.dx - unit.position.dx).abs();
    final dy = (enemy.position.dy - unit.position.dy).abs();
    final score = dx + dy * 2;
    if (score < bestScore) {
      best = enemy;
      bestScore = score;
    }
  }
  return best == null
      ? fallback
      : Offset((unit.position.dx + best.position.dx) / 2, best.position.dy);
}

void main() {
  test('movement targets match per-unit filtering through field and siege', () {
    const size = Size(600, 600);
    final simulation = BattleSimulation(
      record: BattleRecord(
        id: 'battle',
        attackerName: 'Attackers',
        defenderName: 'Defenders',
        attackerId: 'a',
        defenderId: 'd',
        attackerOwnerId: 'player',
        defenderOwnerId: 'enemy',
        locationName: 'Gate',
        rounds: [],
        engagements: const [
          BattleEngagement(
            isCityAssault: false,
            attackerStart: 4,
            defenderStart: 4,
            attackerSurvivors: 3,
            defenderSurvivors: 3,
            attackerWon: true,
          ),
          BattleEngagement(
            isCityAssault: true,
            attackerStart: 4,
            defenderStart: 2,
            attackerSurvivors: 3,
            defenderSurvivors: 1,
            attackerWon: true,
          ),
        ],
        attackerWon: true,
        initialAttackerCount: 4,
        initialDefenderCount: 4,
        initialGarrisonCount: 2,
      ),
      attackerNationality: Nationality.ottomans,
      defenderNationality: Nationality.byzantines,
      screenSize: size,
      isSiege: true,
    )..clashPoint = const Offset(300, 250);
    final attackers = [
      TrackedCircle(const Offset(120, 210), step: const Offset(25, 8)),
      TrackedCircle(const Offset(130, 250), step: const Offset(30, 0)),
      TrackedCircle(const Offset(150, 300)),
      TrackedCircle(const Offset(140, 180)),
    ];
    final defenders = [
      TrackedCircle(const Offset(320, 210)),
      TrackedCircle(const Offset(330, 250)),
      TrackedCircle(const Offset(350, 300)),
      TrackedCircle(const Offset(340, 180)),
    ];
    final garrison = [
      TrackedCircle(const Offset(510, 250)),
      TrackedCircle(const Offset(520, 300)),
    ];
    final countedAttackers = CountedCircles(attackers);
    final countedDefenders = CountedCircles(defenders);
    simulation
      ..attackerCircles = countedAttackers
      ..defenderCircles = countedDefenders
      ..garrisonCircles = garrison
      ..allCircles = [...attackers, ...defenders, ...garrison];

    void checkFrame(BattlePhase phase) {
      simulation
        ..phase = phase
        ..phaseTimer = 0;
      final attackCopy = attackers.map((circle) => circle.copy()).toList();
      final defenseCopy = defenders.map((circle) => circle.copy()).toList();
      final garrisonCopy = garrison.map((circle) => circle.copy()).toList();
      final active = switch (phase) {
        BattlePhase.cityAssault || BattlePhase.flagRaise => garrisonCopy,
        _ => defenseCopy,
      };
      const dt = 0.1;
      final gate = Offset(size.width * 0.84, (size.height - 150) * 0.5 + 100);
      final fallback = phase == BattlePhase.advance
          ? gate
          : simulation.clashPoint;
      for (final circle in attackCopy) {
        final target = phase == BattlePhase.advance
            ? gate
            : previousTarget(circle, active, fallback);
        circle.update(dt, simulation.battleBounds, [], target);
      }
      for (final circle in [...defenseCopy, ...garrisonCopy]) {
        final target = previousTarget(circle, attackCopy, fallback);
        circle.update(
          dt,
          simulation.battleBounds,
          [],
          target,
          isAttacker: false,
        );
      }

      simulation.update(dt);
      expect(
        [
          ...attackers,
          ...defenders,
          ...garrison,
        ].map((circle) => circle.selectedTarget),
        [
          ...attackCopy,
          ...defenseCopy,
          ...garrisonCopy,
        ].map((circle) => circle.selectedTarget),
        reason: phase.name,
      );
    }

    checkFrame(BattlePhase.setup);
    // One target filter per side, plus one attacker and two defender morale filters.
    expect(countedAttackers.filterCalls, 2);
    expect(countedDefenders.filterCalls, 3);

    attackers.first
      ..isDying = true
      ..deathProgress = 0.9;
    defenders.first
      ..isRouting = true
      ..routeDirection = const Offset(1, 0);
    defenders[1].isAlive = false;
    checkFrame(BattlePhase.field);
    expect(attackers.first.isAlive, isFalse);
    checkFrame(BattlePhase.advance);
    expect(defenders[2].isRouting, isTrue);
    checkFrame(BattlePhase.cityAssault);
    for (final guard in garrison) {
      guard.isAlive = false;
    }
    checkFrame(BattlePhase.flagRaise);
  });
}
