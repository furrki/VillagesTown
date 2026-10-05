import 'dart:math' show pi;

import 'package:flutter/material.dart';
import '../../data/models/army.dart';
import '../../data/models/nationality.dart';
import '../components/cloth_flag.dart';

class ArmyVisualMarker extends StatefulWidget {
  final Army army;
  final Nationality nationality;
  final bool isSelected;
  final bool isMarching;
  final bool isBesieging;

  const ArmyVisualMarker({
    super.key,
    required this.army,
    required this.nationality,
    required this.isSelected,
    this.isMarching = false,
    this.isBesieging = false,
  });

  @override
  State<ArmyVisualMarker> createState() => _ArmyVisualMarkerState();
}

class _ArmyVisualMarkerState extends State<ArmyVisualMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flagFlutter;

  @override
  void initState() {
    super.initState();
    _flagFlutter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _flagFlutter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.nationality.color;

    return SizedBox(
      width: 52,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Banner/Pennant
          CustomPaint(
            size: const Size(40, 50),
            painter: _BannerPainter(
              color: color,
              isSelected: widget.isSelected,
              animation: _flagFlutter,
            ),
          ),

          // Flag image
          Positioned(
            top: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                widget.nationality.assetPath,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 24,
                  height: 24,
                  color: color,
                  child: Center(
                    child: Text(
                      widget.army.emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Unit count badge
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color, width: 1.5),
              ),
              child: Text(
                '${widget.army.unitCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Turns indicator (if marching)
          if (widget.isMarching)
            Positioned(
              top: -6,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Text(
                  '${widget.army.turnsUntilArrival}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),

          // Siege indicator
          if (widget.isBesieging)
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.6),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BannerPainter extends CustomPainter {
  final Color color;
  final bool isSelected;
  final Animation<double> animation;

  _BannerPainter({
    required this.color,
    required this.isSelected,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // Pole
    final polePaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const left = 3.0;
    canvas.drawLine(
      const Offset(left, 0),
      Offset(left, size.height - 8),
      polePaint,
    );

    final path = ClothFlag.draw(
      canvas,
      origin: const Offset(left + 1, 2),
      width: size.width * 0.82,
      height: size.height - 12,
      color: color,
      phase: animation.value * 2 * pi,
      flutter: 2.2,
      shape: ClothFlagShape.pointedPennant,
    );

    final borderPaint = Paint()
      ..color = isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2 : 1;
    canvas.drawPath(path, borderPaint);

    // Selection glow
    if (isSelected) {
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6);
      canvas.drawPath(path, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BannerPainter oldDelegate) =>
      color != oldDelegate.color ||
      isSelected != oldDelegate.isSelected ||
      animation != oldDelegate.animation;
}
