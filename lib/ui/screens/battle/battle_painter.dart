import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'battle_circle.dart';
import 'battle_simulation.dart';

/// Floating kill popup for displaying damage numbers.
class KillPopup {
  Offset position;
  final int kills;
  final Color color;
  double life;
  final double maxLife;

  KillPopup({
    required this.position,
    required this.kills,
    required this.color,
    this.life = 1.5,
  }) : maxLife = life;

  void update(double dt) {
    life -= dt;
    position = position + Offset(0, -30 * dt); // Float upward
  }

  double get opacity => (life / maxLife).clamp(0.0, 1.0);
  bool get isAlive => life > 0;
}

/// Spark particle for melee effects.
class SparkParticle {
  Offset position;
  Offset velocity;
  double life;
  final Color color;

  SparkParticle({
    required this.position,
    required this.velocity,
    required this.color,
    this.life = 0.3,
  });

  void update(double dt) {
    position += velocity * dt;
    velocity *= 0.95;
    life -= dt;
  }

  bool get isAlive => life > 0;
}

class BattlePainter extends CustomPainter {
  final BattleSimulation simulation;
  final Map<String, ui.Image?> factionImages;
  final double screenShake;
  final List<KillPopup> killPopups;
  final List<SparkParticle> sparks;

  BattlePainter({
    required this.simulation,
    required this.factionImages,
    this.screenShake = 0,
    this.killPopups = const [],
    this.sparks = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Screen shake is now handled by the parent widget transform
    // No additional shake here to avoid double-shaking

    // Draw clash effect during combat
    if (simulation.isFighting && simulation.combatTime > 3) {
      _drawClashEffect(canvas, simulation.clashPoint);
    }

    // Draw cavalry charge trails during combat
    if (simulation.isFighting) {
      _drawCavalryTrails(canvas);
    }

    // Draw all circles
    for (final circle in simulation.allCircles) {
      if (!circle.isAlive && !circle.isDying) continue;
      _drawCircle(canvas, circle);
    }

    // Draw arrows
    _drawArrows(canvas);

    // Draw sparks for melee
    for (final spark in sparks) {
      _drawSpark(canvas, spark);
    }

    // Draw particles
    for (final circle in simulation.allCircles) {
      for (final particle in circle.deathParticles) {
        _drawParticle(canvas, particle);
      }
    }

    // Draw kill popups
    for (final popup in killPopups) {
      _drawKillPopup(canvas, popup);
    }
  }

  void _drawArrows(Canvas canvas) {
    for (final arrow in simulation.arrows) {
      if (arrow.hasHit) continue;

      canvas.save();
      canvas.translate(arrow.position.dx, arrow.position.dy);
      canvas.rotate(arrow.rotation);

      // Arrow shaft
      final shaftPaint = Paint()
        ..color = arrow.color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(-12, 0), const Offset(4, 0), shaftPaint);

      // Arrowhead
      final headPaint = Paint()
        ..color = arrow.color
        ..style = PaintingStyle.fill;
      final headPath = Path()
        ..moveTo(6, 0)
        ..lineTo(0, -3)
        ..lineTo(0, 3)
        ..close();
      canvas.drawPath(headPath, headPaint);

      // Trail glow
      final trailPaint = Paint()
        ..color = arrow.color.withValues(alpha: 0.3)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawLine(const Offset(-20, 0), const Offset(-8, 0), trailPaint);

      canvas.restore();
    }
  }

  void _drawCircle(Canvas canvas, BattleCircle circle) {
    final center = circle.position;
    final radius = circle.radius;

    // Shadow behind flag
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4 * circle.opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center + const Offset(1, 2), radius, shadowPaint);

    // Glow effect for at-stake circles
    if (circle.isAtStake && !circle.isDying) {
      final glowPaint = Paint()
        ..color = Colors.amber.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(center, radius + 4, glowPaint);
    }

    // Draw faction flag as the main visual
    final image = factionImages[circle.factionId];
    if (image != null) {
      final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
      final dstRect = Rect.fromCircle(center: center, radius: radius);

      canvas.save();
      canvas.clipPath(Path()..addOval(dstRect));
      canvas.drawImageRect(image, srcRect, dstRect, Paint()..color = Colors.white.withValues(alpha: circle.opacity));
      canvas.restore();
    } else {
      // Fallback: solid color circle if no image
      final fillPaint = Paint()
        ..color = circle.color.withValues(alpha: circle.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, fillPaint);
    }

    // Thin border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: circle.opacity * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = circle.isAtStake ? 2 : 1;
    canvas.drawCircle(center, radius, borderPaint);

    // Unit type emoji below the circle
    _drawUnitEmoji(canvas, center, radius, circle);

    // HP bar above the circle
    _drawHpBar(canvas, center, radius, circle);
  }

  void _drawUnitEmoji(Canvas canvas, Offset center, double radius, BattleCircle circle) {
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final isFighting = circle.state == CircleState.fighting;
    final animPhase = isFighting ? (time * 0.8) % (2 * pi) : 0.0; // Very slow, only when fighting

    canvas.save();

    // Position weapon to the right side of the circle
    canvas.translate(center.dx + radius * 0.8, center.dy);

    switch (circle.unitType.category) {
      case 'Ranged':
        _drawBow(canvas, radius, circle, animPhase, isFighting);
        break;
      case 'Cavalry':
        canvas.translate(-radius * 0.8, radius + 4); // Horse below
        _drawHorse(canvas, radius, circle, animPhase, isFighting);
        break;
      default:
        _drawSword(canvas, radius, circle, animPhase, isFighting);
    }

    canvas.restore();
  }

  void _drawSword(Canvas canvas, double radius, BattleCircle circle, double animPhase, bool isFighting) {
    final scale = radius / 18.0;
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final idleSway = sin(time * 0.5) * 0.05; // Very gentle idle sway
    final swingAngle = isFighting ? sin(animPhase) * 0.4 : idleSway;

    canvas.save();
    canvas.rotate(swingAngle - 0.3);

    final bladePaint = Paint()
      ..color = Colors.grey.shade300.withValues(alpha: circle.opacity)
      ..style = PaintingStyle.fill;
    final handlePaint = Paint()
      ..color = Colors.brown.shade700.withValues(alpha: circle.opacity)
      ..style = PaintingStyle.fill;
    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: circle.opacity * 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Blade
    final bladePath = Path();
    bladePath.moveTo(0, -12 * scale);  // Tip
    bladePath.lineTo(3 * scale, -2 * scale);
    bladePath.lineTo(3 * scale, 6 * scale);
    bladePath.lineTo(-3 * scale, 6 * scale);
    bladePath.lineTo(-3 * scale, -2 * scale);
    bladePath.close();
    canvas.drawPath(bladePath, bladePaint);
    canvas.drawPath(bladePath, edgePaint);

    // Guard
    final guardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0, 7 * scale), width: 10 * scale, height: 3 * scale),
      Radius.circular(1 * scale),
    );
    canvas.drawRRect(guardRect, Paint()..color = Colors.amber.shade700.withValues(alpha: circle.opacity));

    // Handle
    final handleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0, 12 * scale), width: 4 * scale, height: 8 * scale),
      Radius.circular(1 * scale),
    );
    canvas.drawRRect(handleRect, handlePaint);

    // Pommel
    canvas.drawCircle(Offset(0, 17 * scale), 2.5 * scale, Paint()..color = Colors.amber.shade800.withValues(alpha: circle.opacity));

    canvas.restore();
  }

  void _drawBow(Canvas canvas, double radius, BattleCircle circle, double animPhase, bool isFighting) {
    final scale = radius / 18.0;
    final drawBack = isFighting ? (sin(animPhase) * 0.5 + 0.5) * 6 * scale : 0.0;

    final woodPaint = Paint()
      ..color = Colors.brown.shade600.withValues(alpha: circle.opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round;
    final stringPaint = Paint()
      ..color = Colors.grey.shade400.withValues(alpha: circle.opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1 * scale;
    final arrowPaint = Paint()
      ..color = Colors.brown.shade800.withValues(alpha: circle.opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round;

    // Bow arc
    final bowPath = Path();
    bowPath.moveTo(-8 * scale, -10 * scale);
    bowPath.quadraticBezierTo(8 * scale, 0, -8 * scale, 10 * scale);
    canvas.drawPath(bowPath, woodPaint);

    // String
    canvas.drawLine(
      Offset(-8 * scale, -10 * scale),
      Offset(-8 * scale + drawBack, 0),
      stringPaint,
    );
    canvas.drawLine(
      Offset(-8 * scale + drawBack, 0),
      Offset(-8 * scale, 10 * scale),
      stringPaint,
    );

    // Arrow (when drawing)
    if (isFighting && drawBack > 2 * scale) {
      canvas.drawLine(
        Offset(-8 * scale + drawBack - 2 * scale, 0),
        Offset(-8 * scale + drawBack + 10 * scale, 0),
        arrowPaint,
      );
      // Arrowhead
      final headPath = Path();
      headPath.moveTo(-8 * scale + drawBack + 12 * scale, 0);
      headPath.lineTo(-8 * scale + drawBack + 8 * scale, -2 * scale);
      headPath.lineTo(-8 * scale + drawBack + 8 * scale, 2 * scale);
      headPath.close();
      canvas.drawPath(headPath, Paint()..color = Colors.grey.shade600.withValues(alpha: circle.opacity));
    }
  }

  void _drawHorse(Canvas canvas, double radius, BattleCircle circle, double animPhase, bool isFighting) {
    final scale = radius / 18.0;
    final gallopOffset = isFighting ? sin(animPhase) * 1 * scale : 0.0; // Gentler gallop
    final legPhase = isFighting ? animPhase : 0.0;

    canvas.save();
    canvas.translate(0, gallopOffset);

    final bodyPaint = Paint()
      ..color = Colors.brown.shade700.withValues(alpha: circle.opacity)
      ..style = PaintingStyle.fill;
    final manePaint = Paint()
      ..color = Colors.brown.shade900.withValues(alpha: circle.opacity)
      ..style = PaintingStyle.fill;
    final legPaint = Paint()
      ..color = Colors.brown.shade800.withValues(alpha: circle.opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * scale
      ..strokeCap = StrokeCap.round;

    // Body (oval)
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 16 * scale, height: 8 * scale),
      bodyPaint,
    );

    // Neck
    final neckPath = Path();
    neckPath.moveTo(6 * scale, -2 * scale);
    neckPath.quadraticBezierTo(10 * scale, -8 * scale, 8 * scale, -12 * scale);
    neckPath.quadraticBezierTo(6 * scale, -10 * scale, 5 * scale, -3 * scale);
    neckPath.close();
    canvas.drawPath(neckPath, bodyPaint);

    // Head
    canvas.drawOval(
      Rect.fromCenter(center: Offset(9 * scale, -13 * scale), width: 6 * scale, height: 4 * scale),
      bodyPaint,
    );

    // Ear
    final earPath = Path();
    earPath.moveTo(8 * scale, -14 * scale);
    earPath.lineTo(7 * scale, -17 * scale);
    earPath.lineTo(9 * scale, -15 * scale);
    earPath.close();
    canvas.drawPath(earPath, bodyPaint);

    // Mane
    final manePath = Path();
    manePath.moveTo(7 * scale, -11 * scale);
    manePath.quadraticBezierTo(4 * scale, -8 * scale, 5 * scale, -4 * scale);
    manePath.quadraticBezierTo(3 * scale, -6 * scale, 6 * scale, -10 * scale);
    canvas.drawPath(manePath, manePaint..style = PaintingStyle.stroke..strokeWidth = 2 * scale);

    // Legs (animated) - gentle movement
    final frontLegAngle1 = sin(legPhase) * 0.2;
    final frontLegAngle2 = sin(legPhase + pi) * 0.2;
    final backLegAngle1 = sin(legPhase + pi / 2) * 0.2;
    final backLegAngle2 = sin(legPhase + pi * 1.5) * 0.2;

    // Front legs
    _drawLeg(canvas, Offset(5 * scale, 3 * scale), 8 * scale, frontLegAngle1, legPaint);
    _drawLeg(canvas, Offset(3 * scale, 3 * scale), 8 * scale, frontLegAngle2, legPaint);

    // Back legs
    _drawLeg(canvas, Offset(-5 * scale, 3 * scale), 8 * scale, backLegAngle1, legPaint);
    _drawLeg(canvas, Offset(-7 * scale, 3 * scale), 8 * scale, backLegAngle2, legPaint);

    // Tail - gentle sway
    final tailPath = Path();
    tailPath.moveTo(-8 * scale, 0);
    tailPath.quadraticBezierTo(
      -14 * scale + sin(animPhase) * 0.5 * scale,
      4 * scale,
      -12 * scale + sin(animPhase) * 1 * scale,
      8 * scale,
    );
    canvas.drawPath(tailPath, manePaint..strokeWidth = 2.5 * scale);

    canvas.restore();
  }

  void _drawLeg(Canvas canvas, Offset start, double length, double angle, Paint paint) {
    canvas.save();
    canvas.translate(start.dx, start.dy);
    canvas.rotate(angle);
    canvas.drawLine(Offset.zero, Offset(0, length), paint);
    // Hoof
    canvas.drawLine(Offset(-1, length), Offset(1, length), paint..strokeWidth = paint.strokeWidth * 1.2);
    canvas.restore();
  }

  void _drawHpBar(Canvas canvas, Offset center, double radius, BattleCircle circle) {
    if (circle.isDying || circle.morale >= 1.0) return; // Don't show if full or dying

    final barWidth = radius * 2;
    final barHeight = 4.0;
    final barTop = center.dy - radius - 8;

    // Background
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx, barTop), width: barWidth, height: barHeight),
      const Radius.circular(2),
    );
    canvas.drawRRect(bgRect, Paint()..color = Colors.black.withValues(alpha: 0.6 * circle.opacity));

    // HP fill
    final fillWidth = barWidth * circle.morale;
    final hpColor = circle.morale > 0.5 ? Colors.green : (circle.morale > 0.25 ? Colors.orange : Colors.red);
    final fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(center.dx - barWidth / 2, barTop - barHeight / 2, fillWidth, barHeight),
      const Radius.circular(2),
    );
    canvas.drawRRect(fillRect, Paint()..color = hpColor.withValues(alpha: circle.opacity));
  }

  void _drawParticle(Canvas canvas, Particle particle) {
    final paint = Paint()
      ..color = particle.color.withValues(alpha: particle.opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(particle.position, particle.radius, paint);
  }

  void _drawClashEffect(Canvas canvas, Offset center) {
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final pulse = 0.5 + sin(time * 10) * 0.5;

    // Radial burst lines
    final linePaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.6 * pulse)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi;
      final innerRadius = 20.0;
      final outerRadius = 40.0 + pulse * 20;
      canvas.drawLine(
        center + Offset(cos(angle) * innerRadius, sin(angle) * innerRadius),
        center + Offset(cos(angle) * outerRadius, sin(angle) * outerRadius),
        linePaint,
      );
    }

    // Center glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.amber.withValues(alpha: 0.8 * pulse),
          Colors.orange.withValues(alpha: 0.4 * pulse),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 50));
    canvas.drawCircle(center, 50, glowPaint);
  }

  void _drawCavalryTrails(Canvas canvas) {
    // Draw motion trails behind charging cavalry
    for (final circle in simulation.allCircles) {
      if (!circle.isAlive || !circle.isCavalry) continue;

      final velocity = circle.velocity;
      if (velocity.distance < 50) continue; // Only draw if moving fast

      // Trail effect
      final trailPaint = Paint()
        ..color = circle.color.withValues(alpha: 0.3)
        ..strokeWidth = circle.radius * 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final normalized = velocity / velocity.distance;
      final trailEnd = circle.position - normalized * 25;
      canvas.drawLine(circle.position, trailEnd, trailPaint);

      // Dust cloud
      final dustPaint = Paint()
        ..color = Colors.brown.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(trailEnd, 8, dustPaint);
    }
  }

  void _drawSpark(Canvas canvas, SparkParticle spark) {
    final paint = Paint()
      ..color = spark.color.withValues(alpha: (spark.life / 0.3).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    // Draw spark as small line to show motion
    final length = spark.velocity.distance * 0.02;
    final normalized = spark.velocity.distance > 0 ? spark.velocity / spark.velocity.distance : Offset.zero;
    final end = spark.position + normalized * length;

    final linePaint = Paint()
      ..color = spark.color.withValues(alpha: (spark.life / 0.3).clamp(0.0, 1.0))
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(spark.position, end, linePaint);
    canvas.drawCircle(spark.position, 2, paint);
  }

  void _drawKillPopup(Canvas canvas, KillPopup popup) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '+${popup.kills}',
        style: TextStyle(
          color: popup.color.withValues(alpha: popup.opacity),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: popup.opacity * 0.8),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      popup.position - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant BattlePainter oldDelegate) => true;
}

class DicePainter extends CustomPainter {
  final List<int> values;
  final Color color;
  final double rollProgress;
  final bool isWinner;

  DicePainter({
    required this.values,
    required this.color,
    required this.rollProgress,
    this.isWinner = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final dieSize = 36.0;
    final spacing = 4.0;
    final totalWidth = values.length * dieSize + (values.length - 1) * spacing;
    final startX = (size.width - totalWidth) / 2;
    final centerY = size.height / 2;

    final random = Random(42); // Fixed seed for consistent "random" during roll

    for (int i = 0; i < values.length; i++) {
      final x = startX + i * (dieSize + spacing);
      final center = Offset(x + dieSize / 2, centerY);

      // Rolling animation
      double displayValue = values[i].toDouble();
      double rotation = 0.0;
      double scale = 1.0;

      if (rollProgress < 1.0) {
        // During roll, show random values and spin
        final t = rollProgress;
        displayValue = (random.nextInt(6) + 1).toDouble();
        rotation = t * pi * 4 + i * 0.5;
        scale = 0.8 + sin(t * pi) * 0.3;
      }

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);
      canvas.scale(scale);

      // Die shadow
      final shadowRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(2, 2), width: dieSize, height: dieSize),
        const Radius.circular(6),
      );
      canvas.drawRRect(shadowRect, Paint()..color = Colors.black.withValues(alpha: 0.4));

      // Die background
      final dieRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: dieSize, height: dieSize),
        const Radius.circular(6),
      );
      canvas.drawRRect(dieRect, Paint()..color = color);

      // Die border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(dieRect, borderPaint);

      // Winner glow
      if (isWinner && rollProgress >= 1.0) {
        final glowPaint = Paint()
          ..color = Colors.greenAccent.withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawRRect(dieRect, glowPaint);
      }

      // Die value
      final textPainter = TextPainter(
        text: TextSpan(
          text: rollProgress >= 1.0 ? '${values[i]}' : '${displayValue.toInt()}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant DicePainter oldDelegate) =>
      oldDelegate.rollProgress != rollProgress || oldDelegate.values != values;
}
