import 'dart:math';
import 'package:flutter/material.dart';

enum TerrainType {
  plains,
  hills,
  forest,
  city,
  coastal,
}

class BattlefieldPainter extends CustomPainter {
  final TerrainType terrain;
  final bool isSiege;
  final double time;
  final List<AtmosphericParticle> particles;

  BattlefieldPainter({
    required this.terrain,
    required this.isSiege,
    required this.time,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Sky gradient
    _drawSky(canvas, size);

    // Distant mountains/horizon
    _drawHorizon(canvas, size);

    // Middle ground (terrain features)
    _drawMiddleGround(canvas, size);

    // Ground/battlefield
    _drawGround(canvas, size);

    // City walls if siege
    if (isSiege) {
      _drawCityWalls(canvas, size);
    }

    // Atmospheric particles
    _drawParticles(canvas, size);

    // Vignette overlay
    _drawVignette(canvas, size);
  }

  void _drawSky(Canvas canvas, Size size) {
    final skyRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.4);

    // Dramatic battle sky - dark orange/red
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF1a1a2e),
        const Color(0xFF16213e),
        const Color(0xFF2c3e50),
        const Color(0xFF4a3728),
      ],
    );

    canvas.drawRect(
      skyRect,
      Paint()..shader = skyGradient.createShader(skyRect),
    );

    // Sun/moon glow
    final sunCenter = Offset(size.width * 0.8, size.height * 0.15);
    final sunGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x60ff6b35),
          const Color(0x30ff6b35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: 80));
    canvas.drawCircle(sunCenter, 80, sunGlow);
  }

  void _drawHorizon(Canvas canvas, Size size) {
    final path = Path();
    final baseY = size.height * 0.35;

    // Mountain silhouettes
    path.moveTo(0, baseY);

    final random = Random(42); // Consistent mountains
    double x = 0;
    while (x < size.width) {
      final peakHeight = 20 + random.nextDouble() * 40;
      final peakWidth = 40 + random.nextDouble() * 60;
      path.lineTo(x + peakWidth / 2, baseY - peakHeight);
      path.lineTo(x + peakWidth, baseY);
      x += peakWidth;
    }

    path.lineTo(size.width, size.height * 0.5);
    path.lineTo(0, size.height * 0.5);
    path.close();

    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF1a1a1a),
    );
  }

  void _drawMiddleGround(Canvas canvas, Size size) {
    final baseY = size.height * 0.45;

    switch (terrain) {
      case TerrainType.hills:
        _drawHills(canvas, size, baseY);
        break;
      case TerrainType.forest:
        _drawTrees(canvas, size, baseY);
        break;
      case TerrainType.coastal:
        _drawWater(canvas, size, baseY);
        break;
      default:
        // Plains - gentle rolling
        _drawRollingPlains(canvas, size, baseY);
    }
  }

  void _drawHills(Canvas canvas, Size size, double baseY) {
    final path = Path();
    path.moveTo(0, baseY);

    // Rolling hills
    for (int i = 0; i < 5; i++) {
      final x1 = size.width * (i / 5);
      final x2 = size.width * ((i + 1) / 5);
      final peakY = baseY - 20 - (i % 2) * 30;
      path.quadraticBezierTo(
        (x1 + x2) / 2,
        peakY,
        x2,
        baseY,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, Paint()..color = const Color(0xFF2d4a2d));
  }

  void _drawTrees(Canvas canvas, Size size, double baseY) {
    final random = Random(123);

    // Draw tree silhouettes
    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final treeHeight = 30 + random.nextDouble() * 40;
      final y = baseY - treeHeight / 2;

      final treePath = Path();
      treePath.moveTo(x, y + treeHeight);
      treePath.lineTo(x - 15, y + treeHeight);
      treePath.lineTo(x, y);
      treePath.lineTo(x + 15, y + treeHeight);
      treePath.close();

      canvas.drawPath(
        treePath,
        Paint()..color = Color.fromARGB(255, 20 + random.nextInt(20), 40 + random.nextInt(20), 20),
      );
    }
  }

  void _drawWater(Canvas canvas, Size size, double baseY) {
    final waterRect = Rect.fromLTWH(0, baseY, size.width, size.height * 0.1);
    final waterGradient = LinearGradient(
      colors: [
        const Color(0xFF1a3a5c),
        const Color(0xFF0d253a),
      ],
    );
    canvas.drawRect(waterRect, Paint()..shader = waterGradient.createShader(waterRect));

    // Wave lines
    final wavePaint = Paint()
      ..color = const Color(0x40ffffff)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 3; i++) {
      final waveY = baseY + 10 + i * 15;
      final wavePath = Path();
      wavePath.moveTo(0, waveY);
      for (double x = 0; x < size.width; x += 20) {
        wavePath.lineTo(x + 10, waveY + sin((x + time * 50) * 0.1) * 3);
      }
      canvas.drawPath(wavePath, wavePaint);
    }
  }

  void _drawRollingPlains(Canvas canvas, Size size, double baseY) {
    final path = Path();
    path.moveTo(0, baseY);

    for (double x = 0; x <= size.width; x += 50) {
      final y = baseY + sin(x * 0.02) * 10;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, Paint()..color = const Color(0xFF3d5a3d));
  }

  void _drawGround(Canvas canvas, Size size) {
    final groundRect = Rect.fromLTWH(0, size.height * 0.5, size.width, size.height * 0.5);

    // Ground gradient
    final groundGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        _getGroundColor(),
        _getGroundColor().withValues(alpha: 0.8),
        const Color(0xFF1a1a1a),
      ],
    );

    canvas.drawRect(groundRect, Paint()..shader = groundGradient.createShader(groundRect));

    // Ground texture lines
    final linePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    for (double y = size.height * 0.55; y < size.height; y += 20) {
      final perspective = (y - size.height * 0.5) / (size.height * 0.5);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint..color = Colors.black.withValues(alpha: 0.1 * perspective),
      );
    }
  }

  Color _getGroundColor() {
    switch (terrain) {
      case TerrainType.plains:
        return const Color(0xFF4a5d3a);
      case TerrainType.hills:
        return const Color(0xFF3d5a3d);
      case TerrainType.forest:
        return const Color(0xFF2d4a2d);
      case TerrainType.city:
        return const Color(0xFF4a4a4a);
      case TerrainType.coastal:
        return const Color(0xFF5a5d4a);
    }
  }

  void _drawCityWalls(Canvas canvas, Size size) {
    final wallY = size.height * 0.45;
    final wallHeight = 60.0;

    // Main wall
    final wallRect = Rect.fromLTWH(
      size.width * 0.55,
      wallY - wallHeight,
      size.width * 0.4,
      wallHeight,
    );

    canvas.drawRect(wallRect, Paint()..color = const Color(0xFF5a5a5a));

    // Wall texture
    final stonePaint = Paint()
      ..color = const Color(0xFF4a4a4a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (double y = wallRect.top; y < wallRect.bottom; y += 10) {
      canvas.drawLine(Offset(wallRect.left, y), Offset(wallRect.right, y), stonePaint);
    }
    for (double x = wallRect.left; x < wallRect.right; x += 15) {
      canvas.drawLine(Offset(x, wallRect.top), Offset(x, wallRect.bottom), stonePaint);
    }

    // Battlements
    final battlementWidth = 12.0;
    final battlementHeight = 15.0;
    for (double x = wallRect.left; x < wallRect.right; x += battlementWidth * 2) {
      canvas.drawRect(
        Rect.fromLTWH(x, wallRect.top - battlementHeight, battlementWidth, battlementHeight),
        Paint()..color = const Color(0xFF5a5a5a),
      );
    }

    // Gate
    final gateWidth = 30.0;
    final gateCenter = wallRect.center.dx;
    canvas.drawRect(
      Rect.fromLTWH(gateCenter - gateWidth / 2, wallY - 40, gateWidth, 40),
      Paint()..color = const Color(0xFF2a2a2a),
    );
  }

  void _drawParticles(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(particle.position, particle.size, paint);
    }
  }

  void _drawVignette(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        Colors.transparent,
        Colors.black.withValues(alpha: 0.3),
        Colors.black.withValues(alpha: 0.7),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  @override
  bool shouldRepaint(covariant BattlefieldPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.particles.length != particles.length;
}

class AtmosphericParticle {
  Offset position;
  Offset velocity;
  double size;
  double opacity;
  Color color;
  double life;

  AtmosphericParticle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.opacity,
    required this.color,
    this.life = 1.0,
  });

  void update(double dt, Size bounds) {
    position += velocity * dt;
    life -= dt * 0.1;

    // Wrap around
    if (position.dx < 0) position = Offset(bounds.width, position.dy);
    if (position.dx > bounds.width) position = Offset(0, position.dy);
    if (position.dy < 0) position = Offset(position.dx, bounds.height);
    if (position.dy > bounds.height) position = Offset(position.dx, 0);
  }
}
