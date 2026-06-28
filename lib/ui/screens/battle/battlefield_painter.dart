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

  /// 0 = open field, 1 = inside the city walls. Drives the scene morph.
  final double cityProgress;

  /// 0 = old flag flying, 1 = conqueror's flag fully raised.
  final double flagRaiseProgress;
  final Color attackerColor;
  final Color defenderColor;

  BattlefieldPainter({
    required this.terrain,
    required this.isSiege,
    required this.time,
    required this.particles,
    this.cityProgress = 0.0,
    this.flagRaiseProgress = 0.0,
    this.attackerColor = Colors.red,
    this.defenderColor = Colors.blue,
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
    if (isSiege || cityProgress > 0) {
      _drawCityWalls(canvas, size);
    }

    // As the attack pushes inside, the walls rise around the view and a gate
    // flagpole comes into play for the flag-raise moment.
    if (cityProgress > 0) {
      _drawCityInterior(canvas, size);
      _drawGateFlag(canvas, size);
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

  /// Buildings closing in on both flanks as the fight moves into the streets.
  void _drawCityInterior(Canvas canvas, Size size) {
    final p = Curves.easeOut.transform(cityProgress.clamp(0.0, 1.0));
    final groundY = size.height * 0.5;

    // Cobblestone tint over the ground
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.width, size.height * 0.5),
      Paint()..color = const Color(0xFF3a3530).withValues(alpha: 0.55 * p),
    );

    // Flanking rows of houses sliding in from the edges
    final houseColors = [const Color(0xFF6b5b4a), const Color(0xFF5a4d3e), const Color(0xFF746252)];
    void houseRow(bool left) {
      for (int i = 0; i < 4; i++) {
        final w = 46.0 + i * 4;
        final h = 70.0 + (i.isEven ? 18 : 0);
        final baseX = left ? -60.0 + i * 52 : size.width + 60.0 - (i + 1) * 52;
        final slide = (left ? -1 : 1) * (1 - p) * 120;
        final rect = Rect.fromLTWH(baseX + slide, groundY - h, w, h);
        canvas.drawRect(rect, Paint()..color = houseColors[i % 3].withValues(alpha: 0.9 * p));
        // Roof
        final roof = Path()
          ..moveTo(rect.left - 4, rect.top)
          ..lineTo(rect.center.dx, rect.top - 18)
          ..lineTo(rect.right + 4, rect.top)
          ..close();
        canvas.drawPath(roof, Paint()..color = const Color(0xFF3e2f25).withValues(alpha: 0.9 * p));
        // Windows
        final winPaint = Paint()..color = const Color(0xFFffcf73).withValues(alpha: 0.5 * p);
        canvas.drawRect(Rect.fromLTWH(rect.left + 10, rect.top + 16, 10, 14), winPaint);
        canvas.drawRect(Rect.fromLTWH(rect.right - 20, rect.top + 16, 10, 14), winPaint);
      }
    }

    houseRow(true);
    houseRow(false);
  }

  /// The gate flagpole. As [flagRaiseProgress] runs 0→1 the defender banner is
  /// hauled down and the conqueror's colours rise in its place.
  void _drawGateFlag(Canvas canvas, Size size) {
    if (flagRaiseProgress <= 0 && isSiege == false && cityProgress < 1) return;

    final poleX = size.width * 0.5;
    final groundY = size.height * 0.48;
    final poleTop = size.height * 0.16;
    final poleHeight = groundY - poleTop;

    // Pole
    canvas.drawRect(
      Rect.fromLTWH(poleX - 2.5, poleTop, 5, poleHeight),
      Paint()..color = const Color(0xFF2a2018),
    );
    // Finial
    canvas.drawCircle(Offset(poleX, poleTop), 5, Paint()..color = const Color(0xFFd9b25a));

    final raise = Curves.easeInOut.transform(flagRaiseProgress.clamp(0.0, 1.0));

    // Defender flag descends in the first half, attacker flag climbs in the second.
    final defenderY = poleTop + raise.clamp(0.0, 1.0) * (poleHeight - 30);
    if (raise < 0.98) {
      _drawBanner(canvas, Offset(poleX, defenderY), defenderColor, 1 - raise);
    }
    if (raise > 0.0) {
      final attackerY = poleTop + (1 - raise) * (poleHeight - 30);
      _drawBanner(canvas, Offset(poleX, attackerY), attackerColor, raise);
    }
  }

  void _drawBanner(Canvas canvas, Offset top, Color color, double alpha) {
    final wave = sin(time * 4) * 4;
    final w = 54.0;
    final h = 34.0;
    final path = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(top.dx + w, top.dy - 4 + wave)
      ..lineTo(top.dx + w, top.dy + h - 4 + wave)
      ..quadraticBezierTo(top.dx + w * 0.5, top.dy + h + 6, top.dx, top.dy + h)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: (0.95 * alpha).clamp(0.0, 1.0)));
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25 * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Emblem dot
    canvas.drawCircle(
      Offset(top.dx + w * 0.45, top.dy + h * 0.5 + wave),
      5,
      Paint()..color = Colors.white.withValues(alpha: 0.7 * alpha),
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
      oldDelegate.time != time ||
      oldDelegate.particles.length != particles.length ||
      oldDelegate.cityProgress != cityProgress ||
      oldDelegate.flagRaiseProgress != flagRaiseProgress;
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
