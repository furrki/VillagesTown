import '../data/models/village.dart';

class BuildingProductionEngine {
  static void consumeAndProduceAll(Village village) {
    final traitBonuses = village.trait.productionBonuses;
    final specBonus = village.specialization == VillageSpecialization.tradeCenter ? 1.25 : 1.0;

    for (final building in village.buildings) {
      // Check if we have enough resources to consume
      bool canProduce = true;
      for (final entry in building.resourcesConsumption.entries) {
        if (!village.isSufficient(entry.key, entry.value)) {
          canProduce = false;
          break;
        }
      }

      if (canProduce) {
        // Consume resources
        for (final entry in building.resourcesConsumption.entries) {
          village.subtractResource(entry.key, entry.value);
        }

        // Produce resources with bonuses
        final happinessModifier = _getHappinessModifier(village.happiness);
        final levelBonus = 1.0 + village.productionBonus;

        for (final entry in building.resourcesProduction.entries) {
          final traitMod = 1.0 + (traitBonuses[entry.key] ?? 0.0);
          final amount = (entry.value * building.level * levelBonus * happinessModifier * traitMod * specBonus).round();
          village.addResource(entry.key, amount);
        }
      }
    }
  }

  static double _getHappinessModifier(int happiness) {
    if (happiness >= 80) return 1.2;
    if (happiness >= 60) return 1.0;
    if (happiness >= 40) return 0.9;
    return 0.8;
  }
}
