import 'resource.dart';

enum VillageTrait {
  fertile('Fertile', 'Rich farmland', '🌾'),
  forested('Forested', 'Dense woodlands', '🌲'),
  mountainous('Mountainous', 'Iron-rich mountains', '⛰️'),
  tradeCrossroads('Trade Crossroads', 'Major trade hub', '🏛️'),
  coastal('Coastal', 'Port access', '⚓'),
  strategic('Strategic', 'Defensive stronghold', '🏰'),
  none('None', '', '');

  final String displayName;
  final String description;
  final String emoji;
  const VillageTrait(this.displayName, this.description, this.emoji);

  /// Resource production multiplier for this trait.
  /// Returns a map of resource -> bonus multiplier (e.g. 0.5 = +50%).
  Map<Resource, double> get productionBonuses => switch (this) {
        fertile => {Resource.food: 0.5},
        forested => {Resource.wood: 0.5},
        mountainous => {Resource.iron: 0.5},
        tradeCrossroads => {Resource.gold: 0.5},
        coastal => {Resource.gold: 0.25, Resource.food: 0.25},
        strategic => {},
        none => {},
      };

  /// Extra garrison regen rate multiplier for strategic trait.
  double get garrisonRegenBonus => this == strategic ? 0.25 : 0.0;

  /// Fortress acts as +1 level higher for strategic trait.
  int get fortressLevelBonus => this == strategic ? 1 : 0;
}
