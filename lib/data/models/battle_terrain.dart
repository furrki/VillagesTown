/// Terrain types that affect battle modifiers.
enum BattleTerrain {
  openField(
    displayName: 'Open Field',
    emoji: '🏜️',
    description: 'Flat ground favoring cavalry charges',
    cavalryChargeMod: 1.20,
    rangedMod: 1.0,
    defenseMod: 1.0,
    movementMod: 1.0,
  ),
  hill(
    displayName: 'Hill',
    emoji: '⛰️',
    description: 'High ground favoring archers and defense',
    cavalryChargeMod: 0.85,
    rangedMod: 1.10,
    defenseMod: 1.20,
    movementMod: 0.90,
  ),
  riverCrossing(
    displayName: 'River Crossing',
    emoji: '🌊',
    description: 'Water obstacle devastating to cavalry',
    cavalryChargeMod: 0.80,
    rangedMod: 1.30,
    defenseMod: 1.10,
    movementMod: 0.80,
  ),
  forest(
    displayName: 'Forest',
    emoji: '🌲',
    description: 'Dense woods hindering cavalry and archers',
    cavalryChargeMod: 0.75,
    rangedMod: 0.85,
    defenseMod: 1.15,
    movementMod: 0.85,
  );

  final String displayName;
  final String emoji;
  final String description;
  final double cavalryChargeMod;
  final double rangedMod;
  final double defenseMod;
  final double movementMod;

  const BattleTerrain({
    required this.displayName,
    required this.emoji,
    required this.description,
    required this.cavalryChargeMod,
    required this.rangedMod,
    required this.defenseMod,
    required this.movementMod,
  });
}
