import 'dart:math';
import 'dart:ui';
import '../../../data/models/unit_type.dart';

enum CircleState {
  ready,
  charging,
  fighting,
  retreating,
  routing,
  dead,
}

class BattleCircle {
  Offset position;
  Offset velocity;
  final String factionId;
  final Color color;
  final String? assetPath;
  final UnitType unitType;
  bool isAlive;
  bool isAtStake;
  double scale;
  double opacity;
  double morale; // 0.0 to 1.0
  CircleState state;
  bool isGeneral; // Generals boost morale

  // For death animation
  bool isDying;
  double deathProgress;
  List<Particle> deathParticles;

  // For routing
  bool isRouting;
  Offset? routeDirection;

  // Helper getters for unit category
  String get category => unitType.category;
  bool get isRanged => category == 'Ranged';
  bool get isCavalry => category == 'Cavalry';
  bool get isInfantry => category == 'Infantry';

  BattleCircle({
    required this.position,
    required this.factionId,
    required this.color,
    this.assetPath,
    this.unitType = UnitType.militia,
    this.isAlive = true,
    this.isAtStake = false,
    this.scale = 1.0,
    this.opacity = 1.0,
    this.morale = 1.0,
    this.isGeneral = false,
    this.baseRadiusOverride = 0,
  })  : velocity = Offset.zero,
        state = CircleState.ready,
        isDying = false,
        deathProgress = 0.0,
        deathParticles = [],
        isRouting = false,
        routeDirection = null;

  static const double defaultBaseRadius = 9.0;
  double baseRadiusOverride;

  double get radius => (baseRadiusOverride > 0 ? baseRadiusOverride : defaultBaseRadius) * scale;

  // Store home position for regrouping
  Offset? homePosition;

  void update(double dt, Rect bounds, List<BattleCircle> others, Offset targetCenter, {bool isAttacker = true, bool isEngaging = false, bool isRegrouping = false}) {
    if (!isAlive && !isDying && !isRouting) return;

    // Remember home position
    homePosition ??= position;

    // Handle death animation
    if (isDying) {
      deathProgress += dt * 3.0;
      scale = max(0, 1.0 - deathProgress);
      opacity = max(0, 1.0 - deathProgress);

      for (final p in deathParticles) {
        p.update(dt);
      }
      deathParticles.removeWhere((p) => p.life <= 0);

      if (deathProgress >= 1.0) {
        isAlive = false;
        isDying = false;
        state = CircleState.dead;
      }
      return;
    }

    // Handle routing - flee off screen
    if (isRouting) {
      state = CircleState.routing;
      routeDirection ??= Offset(isAttacker ? -1 : 1, (Random().nextDouble() - 0.5) * 0.5);
      velocity += routeDirection! * 400 * dt;
      position += velocity * dt;
      velocity *= 0.95;
      opacity = max(0, opacity - dt * 0.6);

      if (position.dx < -50 || position.dx > bounds.right + 50) {
        isAlive = false;
        isRouting = false;
        state = CircleState.dead;
      }
      return;
    }

    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;

    if (isEngaging) {
      state = CircleState.fighting;

      // Ranged units stay back and fire - they don't charge into melee
      if (isRanged) {
        // Hold position with slight draw-and-fire animation
        velocity *= 0.9;
        final drawBack = sin(time * 3 + position.hashCode) * 2.0;
        position = Offset(
          homePosition!.dx + (isAttacker ? -drawBack : drawBack),
          homePosition!.dy + cos(time * 4 + position.hashCode) * 0.5,
        );
      } else {
        // ENGAGE: Melee/cavalry move toward clash point
        final toTarget = targetCenter - position;
        final dist = toTarget.distance;
        if (dist > 3) {
          // Smooth, deliberate march toward target
          final moveSpeed = isCavalry ? 180.0 : 120.0;
          velocity = toTarget / dist * moveSpeed;
        } else {
          velocity = Offset.zero;
        }
        position += velocity * dt;

        // Slight jitter during combat (fighting animation)
        position += Offset(
          sin(time * 8 + position.hashCode) * 0.5,
          cos(time * 9 + position.hashCode) * 0.5,
        );
      }

    } else if (isRegrouping) {
      // REGROUP: Return to home position
      state = CircleState.retreating;
      final toHome = homePosition! - position;
      final dist = toHome.distance;
      if (dist > 5) {
        velocity = toHome / dist * 100.0;
      } else {
        velocity = Offset.zero;
      }
      position += velocity * dt;

    } else {
      // PREPARE: Hold formation with subtle breathing
      state = CircleState.ready;
      velocity *= 0.9; // Slow down

      // Very subtle breathing/ready stance - not chaotic bobbing
      final breathe = sin(time * 1.5 + position.hashCode * 0.01) * 0.3;
      scale = 1.0 + breathe * 0.02;
    }

    // Gentle collision avoidance (not bouncy)
    for (final other in others) {
      if (other == this || !other.isAlive) continue;
      final diff = position - other.position;
      final dist = diff.distance;
      final minDist = radius + other.radius + 2;
      if (dist < minDist && dist > 0) {
        position += diff / dist * (minDist - dist) * 0.5;
      }
    }

    // Keep in bounds
    position = Offset(
      position.dx.clamp(bounds.left + radius, bounds.right - radius),
      position.dy.clamp(bounds.top + radius, bounds.bottom - radius),
    );

    // Scale for at-stake units
    if (isAtStake && !isEngaging) {
      scale = 1.1 + sin(time * 4) * 0.05;
    }

    // Opacity based on morale
    if (!isDying && !isRouting) {
      opacity = 0.7 + morale * 0.3;
    }
  }

  void route() {
    if (isRouting || isDying || !isAlive) return;
    isRouting = true;
    state = CircleState.routing;
  }

  void damageMorale(double amount) {
    morale = max(0, morale - amount);
    // Check for routing
    if (morale <= 0.2 && !isRouting && Random().nextDouble() > morale) {
      route();
    }
  }

  void die() {
    if (isDying || !isAlive) return;
    isDying = true;
    deathProgress = 0.0;

    // Create death particles - more dramatic burst
    final random = Random();
    for (int i = 0; i < 20; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = 150 + random.nextDouble() * 200;
      deathParticles.add(Particle(
        position: position,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        color: color,
        radius: 4 + random.nextDouble() * 6,
        life: 0.8 + random.nextDouble() * 0.5,
      ));
    }
  }

  void moveToward(Offset target, double speed) {
    final diff = target - position;
    if (diff.distance > 1) {
      velocity += diff / diff.distance * speed;
    }
  }
}

class Particle {
  Offset position;
  Offset velocity;
  final Color color;
  double radius;
  double life;
  final double maxLife;

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.radius,
    required this.life,
  }) : maxLife = life;

  void update(double dt) {
    position += velocity * dt;
    velocity *= 0.95;
    life -= dt;
    radius = max(0, radius * (life / maxLife));
  }

  double get opacity => (life / maxLife).clamp(0.0, 1.0);
}
