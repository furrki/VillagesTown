enum GameModifier {
  // Resource Modifiers
  scarcity(
    'Scarcity',
    'All production halved',
    '🏜️',
    category: ModifierCategory.resource,
  ),
  abundance(
    'Abundance',
    'All production doubled',
    '🌾',
    category: ModifierCategory.resource,
  ),
  goldStandard(
    'Gold Standard',
    'Everything costs 2x gold',
    '💎',
    category: ModifierCategory.resource,
  ),

  // Military Modifiers
  peasantWar(
    'Peasant War',
    'Only militia and spearmen available',
    '🪓',
    category: ModifierCategory.military,
  ),
  noFortress(
    'No Fortress',
    'Fortresses disabled',
    '🏚️',
    category: ModifierCategory.military,
  ),

  // Map Modifiers
  fogEternal(
    'Fog Eternal',
    'Vision range halved',
    '🌫️',
    category: ModifierCategory.map,
  ),
  openBook(
    'Open Book',
    'No fog of war',
    '📖',
    category: ModifierCategory.map,
  ),

  // Pacing Modifiers
  blitz(
    'Blitz',
    'Game ends at turn 30, highest score wins',
    '⚡',
    category: ModifierCategory.pacing,
  ),
  suddenDeath(
    'Sudden Death',
    'Lose 1 village = eliminated',
    '💀',
    category: ModifierCategory.pacing,
  );

  final String displayName;
  final String description;
  final String emoji;
  final ModifierCategory category;

  const GameModifier(
    this.displayName,
    this.description,
    this.emoji, {
    required this.category,
  });

  double get productionMultiplier => switch (this) {
        scarcity => 0.5,
        abundance => 2.0,
        _ => 1.0,
      };

  double get goldCostMultiplier => switch (this) {
        goldStandard => 2.0,
        _ => 1.0,
      };

  /// Modifiers that conflict with each other (can't pick both).
  List<GameModifier> get conflicts => switch (this) {
        scarcity => [abundance],
        abundance => [scarcity],
        fogEternal => [openBook],
        openBook => [fogEternal],
        _ => [],
      };

  /// Score bonus multiplier for having this modifier active.
  double get scoreBonusMultiplier => switch (this) {
        scarcity => 1.15,
        goldStandard => 1.1,
        peasantWar => 1.2,
        noFortress => 1.1,
        fogEternal => 1.15,
        blitz => 1.2,
        suddenDeath => 1.25,
        abundance => 0.8,
        openBook => 0.9,
      };
}

enum ModifierCategory {
  resource('RESOURCE'),
  military('MILITARY'),
  map('MAP'),
  pacing('PACING');

  final String displayName;
  const ModifierCategory(this.displayName);
}
