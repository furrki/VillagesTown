import 'package:flutter/material.dart';
import '../../data/models/army.dart';
import '../../data/models/nationality.dart';

class ArmyVisualMarker extends StatelessWidget {
  final Army army;
  final Nationality nationality;
  final bool isSelected;
  final bool isMarching;

  const ArmyVisualMarker({
    super.key,
    required this.army,
    required this.nationality,
    required this.isSelected,
    this.isMarching = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = nationality.color;

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
              isSelected: isSelected,
            ),
          ),

          // Flag image
          Positioned(
            top: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                nationality.assetPath,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 24,
                  height: 24,
                  color: color,
                  child: Center(
                    child: Text(
                      army.emoji,
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
                '${army.unitCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Turns indicator (if marching)
          if (isMarching)
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
                  '${army.turnsUntilArrival}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
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

  _BannerPainter({required this.color, required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color,
          Color.lerp(color, Colors.black, 0.3)!,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Pole
    final polePaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height - 8),
      polePaint,
    );

    // Banner shape (pennant)
    final path = Path();
    final bannerWidth = size.width * 0.85;
    final left = (size.width - bannerWidth) / 2;

    path.moveTo(left, 2);
    path.lineTo(left + bannerWidth, 2);
    path.lineTo(left + bannerWidth, 32);
    path.lineTo(left + bannerWidth / 2, 40); // Point
    path.lineTo(left, 32);
    path.close();

    // Shadow
    canvas.drawShadow(path, Colors.black, 3, true);

    // Banner fill
    canvas.drawPath(path, paint);

    // Border
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
      color != oldDelegate.color || isSelected != oldDelegate.isSelected;
}
