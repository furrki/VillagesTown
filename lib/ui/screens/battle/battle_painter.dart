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

    // Draw clash effect in center during melee phase
    if (simulation.phase == BattlePhase.meleeClash) {
      _drawClashEffect(canvas, simulation.clashPoint);
    }

    // Draw cavalry charge trails during cavalry phase
    if (simulation.phase == BattlePhase.cavalryCharge) {
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

    // Small unit type badge in top-right
    _drawUnitTypeBadge(canvas, center, radius, circle);
  }

  void _drawUnitTypeBadge(Canvas canvas, Offset center, double radius, BattleCircle circle) {
    // Badge position: top-right of the circle
    final badgeCenter = center + Offset(radius * 0.6, -radius * 0.6);
    final badgeRadius = max(4.0, radius * 0.35);

    // Badge background
    final bgColor = circle.isRanged
        ? Colors.green.shade700
        : circle.isCavalry
            ? Colors.blue.shade700
            : Colors.brown.shade600;

    final bgPaint = Paint()
      ..color = bgColor.withValues(alpha: circle.opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(badgeCenter, badgeRadius, bgPaint);

    // Badge border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: circle.opacity * 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(badgeCenter, badgeRadius, borderPaint);

    // Draw icon inside badge
    final iconPaint = Paint()
      ..color = Colors.white.withValues(alpha: circle.opacity)
      ..style = PaintingStyle.fill;

    final iconSize = badgeRadius * 0.7;

    if (circle.isRanged) {
      // Arrow icon
      final path = Path();
      path.moveTo(badgeCenter.dx + iconSize, badgeCenter.dy);
      path.lineTo(badgeCenter.dx - iconSize * 0.5, badgeCenter.dy - iconSize * 0.5);
      path.lineTo(badgeCenter.dx - iconSize * 0.2, badgeCenter.dy);
      path.lineTo(badgeCenter.dx - iconSize * 0.5, badgeCenter.dy + iconSize * 0.5);
      path.close();
      canvas.drawPath(path, iconPaint);
    } else if (circle.isCavalry) {
      // Horse head / chevron
      final path = Path();
      path.moveTo(badgeCenter.dx + iconSize * 0.6, badgeCenter.dy);
      path.lineTo(badgeCenter.dx - iconSize * 0.4, badgeCenter.dy - iconSize * 0.6);
      path.lineTo(badgeCenter.dx, badgeCenter.dy);
      path.lineTo(badgeCenter.dx - iconSize * 0.4, badgeCenter.dy + iconSize * 0.6);
      path.close();
      canvas.drawPath(path, iconPaint);
    } else {
      // Shield for infantry
      final shieldRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: badgeCenter, width: iconSize * 1.2, height: iconSize * 1.4),
        const Radius.circular(1),
      );
      canvas.drawRRect(shieldRect, iconPaint);
    }
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
