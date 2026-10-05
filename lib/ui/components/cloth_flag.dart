import 'dart:math' as math;

import 'package:flutter/material.dart';

enum ClothFlagShape { rectangle, pointedPennant }

/// Shared cloth shading and edge motion for the game's hanging banners.
class ClothFlag {
  static Path draw(
    Canvas canvas, {
    required Offset origin,
    required double width,
    required double height,
    required Color color,
    required double phase,
    double alpha = 1,
    double flutter = 3,
    ClothFlagShape shape = ClothFlagShape.rectangle,
  }) {
    const segments = 12;
    double ripple(double u, [double offset = 0]) {
      final anchored = math.pow(u, 1.25).toDouble();
      return math.sin(phase - u * 2.8 + offset) * flutter * anchored;
    }

    final path = Path()..moveTo(origin.dx, origin.dy);
    for (var i = 1; i <= segments; i++) {
      final u = i / segments;
      path.lineTo(origin.dx + width * u, origin.dy + ripple(u));
    }

    if (shape == ClothFlagShape.pointedPennant) {
      final rightX = origin.dx + width;
      path.lineTo(rightX, origin.dy + height * 0.78 + ripple(1, 0.45));
      path.quadraticBezierTo(
        origin.dx + width * 0.78,
        origin.dy + height + ripple(0.72, 0.8),
        origin.dx + width * 0.5,
        origin.dy + height + ripple(0.5, 0.9),
      );
      path.quadraticBezierTo(
        origin.dx + width * 0.22,
        origin.dy + height + ripple(0.28, 0.8),
        origin.dx,
        origin.dy + height * 0.78 + ripple(0, 0.45),
      );
    } else {
      for (var i = segments - 1; i >= 0; i--) {
        final u = i / segments;
        path.lineTo(
          origin.dx + width * u,
          origin.dy + height + ripple(u, 0.78),
        );
      }
    }
    path.close();

    final clothRect = Rect.fromLTWH(
      origin.dx,
      origin.dy - flutter,
      width,
      height + flutter * 2,
    );
    final dark = Color.lerp(
      color,
      Colors.black,
      0.42,
    )!.withValues(alpha: alpha);
    final mid = Color.lerp(color, Colors.black, 0.12)!.withValues(alpha: alpha);
    final light = Color.lerp(
      color,
      Colors.white,
      0.22,
    )!.withValues(alpha: alpha);

    canvas.drawShadow(
      path,
      Colors.black.withValues(alpha: 0.35 * alpha),
      2,
      true,
    );
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      clothRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [dark, mid, light, mid, dark],
          stops: const [0, 0.2, 0.42, 0.7, 1],
        ).createShader(clothRect),
    );

    // Fine raised and recessed creases make the surface read as folded fabric.
    for (var i = 1; i <= 3; i++) {
      final u = i / 4;
      final x = origin.dx + width * u + ripple(u) * 0.24;
      final crease = Path()
        ..moveTo(x, origin.dy - flutter)
        ..cubicTo(
          x - 1.4,
          origin.dy + height * 0.3,
          x + 1.4,
          origin.dy + height * 0.68,
          x + ripple(u, 0.8) * 0.2,
          origin.dy + height + flutter,
        );
      canvas.drawPath(
        crease,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.18 * alpha)
          ..strokeWidth = math.max(1, width * 0.035)
          ..style = PaintingStyle.stroke,
      );
      canvas.drawPath(
        crease.shift(const Offset(0.8, 0)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.17 * alpha)
          ..strokeWidth = math.max(0.6, width * 0.018)
          ..style = PaintingStyle.stroke,
      );
    }
    canvas.restore();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.32 * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    canvas.drawLine(
      origin,
      Offset(origin.dx, origin.dy + height * 0.78),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.24 * alpha)
        ..strokeWidth = math.max(1, width * 0.035),
    );
    return path;
  }
}
