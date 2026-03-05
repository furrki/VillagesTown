import 'dart:ui';

enum Difficulty {
  easy(
    'Easy',
    'Forgiving start, weaker AI',
    aiResourceMod: 0.8,
    playerStartGoldBonus: 500,
    scoreMultiplier: 0.5,
  ),
  normal(
    'Normal',
    'Standard experience',
    aiResourceMod: 1.0,
    playerStartGoldBonus: 0,
    scoreMultiplier: 1.0,
  ),
  hard(
    'Hard',
    'Stronger AI, no mercy',
    aiResourceMod: 1.2,
    playerStartGoldBonus: 0,
    scoreMultiplier: 1.5,
  ),
  legendary(
    'Legendary',
    'Crushing AI, fewer resources',
    aiResourceMod: 1.4,
    playerStartGoldBonus: -200,
    scoreMultiplier: 2.0,
  );

  final String displayName;
  final String description;
  final double aiResourceMod;
  final int playerStartGoldBonus;
  final double scoreMultiplier;

  const Difficulty(
    this.displayName,
    this.description, {
    required this.aiResourceMod,
    required this.playerStartGoldBonus,
    required this.scoreMultiplier,
  });

  Color get color => switch (this) {
        easy => const Color(0xFF4CAF50),
        normal => const Color(0xFF90CAF9),
        hard => const Color(0xFFFF9800),
        legendary => const Color(0xFFFF1744),
      };
}
