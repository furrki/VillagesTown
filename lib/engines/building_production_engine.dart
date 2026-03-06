import '../data/models/resource.dart';
import '../data/models/village.dart';
import 'event_engine.dart';
import 'game_manager.dart';

class BuildingProductionEngine {
  static void consumeAndProduceAll(Village village) {
    final game = GameManager.shared;
    final traitBonuses = village.trait.productionBonuses;
    final specBonus = village.specialization == VillageSpecialization.tradeCenter ? 1.25 : 1.0;

    // Event modifiers
    final foodEventMod = EventEngine.foodProductionModifier(game);
    final goldEventMod = EventEngine.goldProductionModifier(game, village.id);

    // Difficulty modifier (AI villages produce more/less)
    final difficultyMod = (village.owner != 'player' && village.owner != 'neutral')
        ? (game.difficulty?.aiResourceMod ?? 1.0)
        : 1.0;

    // Game modifier: scarcity/abundance production multiplier
    double modifierProdMod = 1.0;
    for (final mod in game.activeModifiers) {
      modifierProdMod *= mod.productionMultiplier;
    }

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

          // Apply event modifiers per resource type
          double eventMod = 1.0;
          if (entry.key == Resource.food) eventMod = foodEventMod;
          if (entry.key == Resource.gold) eventMod = goldEventMod;

          final amount = (entry.value * building.level * levelBonus * happinessModifier * traitMod * specBonus * eventMod * difficultyMod * modifierProdMod).round();
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
