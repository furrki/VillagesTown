enum VictoryType {
  domination(
    'Domination',
    'Control 70% of all villages',
    '⚔️',
  ),
  economic(
    'Economic',
    'Accumulate 10,000 gold and control 3 Trade Crossroads',
    '💰',
  ),
  military(
    'Military',
    'Win 15 battles and field the strongest army',
    '🗡️',
  ),
  imperial(
    'Imperial',
    'Upgrade 5 villages to City level',
    '🏛️',
  );

  final String displayName;
  final String description;
  final String emoji;
  const VictoryType(this.displayName, this.description, this.emoji);

  /// Score bonus for winning via this victory type.
  int get scoreBonus => switch (this) {
        domination => 0,
        economic => 200,
        military => 300,
        imperial => 500,
      };
}

class VictoryProgress {
  final VictoryType type;
  final double progress; // 0.0 to 1.0
  final String description;
  final bool achieved;

  const VictoryProgress({
    required this.type,
    required this.progress,
    required this.description,
    required this.achieved,
  });
}

class GameScore {
  final int villageScore;
  final int battleScore;
  final int populationScore;
  final int goldScore;
  final int speedBonus;
  final int victoryTypeBonus;
  final double difficultyMultiplier;

  const GameScore({
    required this.villageScore,
    required this.battleScore,
    required this.populationScore,
    required this.goldScore,
    required this.speedBonus,
    required this.victoryTypeBonus,
    this.difficultyMultiplier = 1.0,
  });

  int get subtotal =>
      villageScore +
      battleScore +
      populationScore +
      goldScore +
      speedBonus +
      victoryTypeBonus;

  int get total => (subtotal * difficultyMultiplier).round();
}
