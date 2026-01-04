import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/army.dart';
import '../../data/models/unit_type.dart';

class ArmyVisualMarker extends StatelessWidget {
  final Army army;
  final bool isSelected;
  final bool isMarching;

  const ArmyVisualMarker({
    super.key,
    required this.army,
    required this.isSelected,
    this.isMarching = false,
  });

  @override
  Widget build(BuildContext context) {
    final unitType = army.primaryUnitType ?? UnitType.militia;
    final category = unitType.category; // Infantry, Ranged, Cavalry
    final isPlayer = army.owner == 'player';
    
    final color = isPlayer ? const Color(0xFF3B82F6) : const Color(0xFFEF4444);
    final size = isMarching ? 40.0 : 44.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Shadow / Glow if selected
          if (isSelected)
            Container(
              width: size + 8,
              height: size + 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                shape: category == 'Cavalry' ? BoxShape.rectangle : (category == 'Ranged' ? BoxShape.circle : BoxShape.rectangle),
                borderRadius: category == 'Infantry' ? BorderRadius.circular(8) : null,
                boxShadow: [
                  BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 8, spreadRadius: 1),
                ],
              ),
              transform: category == 'Cavalry' ? (Matrix4.identity()..rotateZ(math.pi / 4)) : null,
            ),

          // 2. Main Shape
          _buildShape(context, category, color, size),

          // 3. Icon / Emoji
          Center(
            child: Text(
              _getEmoji(unitType),
              style: TextStyle(
                fontSize: size * 0.55,
                shadows: [
                  Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 2, offset: const Offset(0, 1)),
                ],
              ),
            ),
          ),

          // 4. Strength Indicator (Bottom Right)
          Positioned(
            bottom: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24, width: 0.5),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 2)],
              ),
              child: Text(
                '${army.unitCount}',
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // 5. Turns Tag (If Marching)
          if (isMarching)
             Positioned(
              top: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                     BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 2),
                  ],
                ),
                child: Text(
                  '${army.turnsUntilArrival}t',
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

  Widget _buildShape(BuildContext context, String category, Color color, double size) {
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withOpacity(0.8),
        color,
      ],
    );

    if (category == 'Cavalry') {
      // Diamond Shape (Rotated Square)
      return Transform.rotate(
        angle: math.pi / 4,
        child: Container(
          width: size * 0.70,
          height: size * 0.70,
          decoration: BoxDecoration(
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 5,
                offset: const Offset(2, 2),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
          ),
        ),
      );
    } else if (category == 'Ranged') {
       // Circle
       return Container(
         width: size,
         height: size,
         decoration: BoxDecoration(
           gradient: gradient,
           shape: BoxShape.circle,
           boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
         ),
       );
    } else {
      // Infantry - Rounded Square
      return Container(
        width: size * 0.9,
        height: size * 0.9,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(8),
           boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        ),
      );
    }
  }

  String _getEmoji(UnitType type) {
    // Basic mapping, though unit types likely have .emoji property themselves which is better to use if available.
    // Assuming for now I can map them myself or if `type` has .emoji access.
    // The previous code didn't use type.emoji, so I will map manually to be safe, or check model.
    // Checking previous context, UnitType has .emoji
    return type.emoji;
  }
}
