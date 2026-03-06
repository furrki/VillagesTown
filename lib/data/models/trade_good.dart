import 'resource.dart';
import 'village_trait.dart';

enum TradeGood {
  grain('Grain', '🌾', 10),
  ironOre('Iron Ore', '⛏️', 25),
  silk('Silk', '🧵', 50);

  final String displayName;
  final String emoji;
  final int basePrice;
  const TradeGood(this.displayName, this.emoji, this.basePrice);

  Resource? get convertibleTo => switch (this) {
        grain => Resource.food,
        ironOre => Resource.iron,
        silk => null,
      };

  double priceModifier(VillageTrait trait) => switch (this) {
        grain => switch (trait) {
            VillageTrait.fertile => 0.5,
            VillageTrait.mountainous => 1.5,
            VillageTrait.forested => 1.0,
            VillageTrait.tradeCrossroads => 1.0,
            VillageTrait.coastal => 0.8,
            VillageTrait.strategic => 1.1,
            VillageTrait.none => 1.0,
          },
        ironOre => switch (trait) {
            VillageTrait.fertile => 1.3,
            VillageTrait.mountainous => 0.5,
            VillageTrait.forested => 0.8,
            VillageTrait.tradeCrossroads => 1.0,
            VillageTrait.coastal => 1.3,
            VillageTrait.strategic => 0.7,
            VillageTrait.none => 1.0,
          },
        silk => switch (trait) {
            VillageTrait.fertile => 1.0,
            VillageTrait.mountainous => 1.3,
            VillageTrait.forested => 1.5,
            VillageTrait.tradeCrossroads => 0.6,
            VillageTrait.coastal => 0.9,
            VillageTrait.strategic => 1.2,
            VillageTrait.none => 1.0,
          },
      };

  int buyPrice(VillageTrait trait) => (basePrice * priceModifier(trait)).round();

  int sellPrice(VillageTrait trait) => (buyPrice(trait) * 0.8).round();
}
