enum AIPersonality {
  aggressive('Aggressive', 0.9, 0.3, 0.8),
  economic('Economic', 0.3, 0.9, 0.5),
  balanced('Balanced', 0.6, 0.6, 0.6);

  final String description;
  final double aggressionBias;
  final double economicBias;
  final double expansionBias;

  const AIPersonality(this.description, this.aggressionBias, this.economicBias, this.expansionBias);
}
