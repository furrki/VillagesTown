import 'package:flutter/material.dart';

enum Terrain {
  plains('Plains', Color(0xFF90EE90), 1, 0.0, true),
  forest('Forest', Color(0xFF228B22), 2, 0.1, true),
  mountains('Mountains', Color(0xFF808080), 3, 0.3, true),
  hills('Hills', Color(0xFFA0522D), 2, 0.2, true),
  river('River', Color(0xFF4169E1), 3, 0.0, false),
  coast('Coast', Color(0xFF87CEEB), 2, 0.0, false);

  final String displayName;
  final Color color;
  final int movementCost;
  final double defenseBonus;
  final bool canBuildOn;

  const Terrain(
    this.displayName,
    this.color,
    this.movementCost,
    this.defenseBonus,
    this.canBuildOn,
  );
}
