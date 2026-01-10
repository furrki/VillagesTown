import 'package:flutter/material.dart';

/// Stacked bar showing garrison vs army strength.
class DefenderStrengthBar extends StatelessWidget {
  final int garrisonStrength;
  final int armyStrength;
  final double height;
  final bool showLegend;

  const DefenderStrengthBar({
    super.key,
    required this.garrisonStrength,
    required this.armyStrength,
    this.height = 8.0,
    this.showLegend = true,
  });

  static const garrisonColor = Color(0xFFFFB74D); // Amber
  static const armyColor = Color(0xFF42A5F5); // Blue

  @override
  Widget build(BuildContext context) {
    final total = garrisonStrength + armyStrength;
    if (total == 0) {
      return SizedBox(height: showLegend ? height + 20 : height);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLegend) ...[
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shield,
                    size: 12,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$total',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _LegendDot(color: garrisonColor, label: '$garrisonStrength'),
              const SizedBox(width: 6),
              _LegendDot(color: armyColor, label: '$armyStrength'),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: Row(
              children: [
                if (garrisonStrength > 0)
                  Expanded(
                    flex: garrisonStrength,
                    child: Container(color: garrisonColor),
                  ),
                if (armyStrength > 0)
                  Expanded(
                    flex: armyStrength,
                    child: Container(color: armyColor),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}
