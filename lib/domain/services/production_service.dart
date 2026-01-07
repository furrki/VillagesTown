import '../entities/village.dart';
import '../entities/building.dart';
import '../value_objects/resources.dart';

/// Pure production calculation service.
/// All methods compute results without side effects.
class ProductionService {
  const ProductionService();

  /// Calculate total production for a village this turn.
  ResourceBundle calculateProduction(Village village) {
    var production = ResourceBundle.empty;
    final modifier = _getHappinessModifier(village.happiness);

    for (final building in village.buildings) {
      // Only produce if village can afford consumption
      if (_canProduce(building, village.resources)) {
        final output = building.production.scale(modifier);
        production = production + output;
      }
    }

    // Apply village level bonus
    final levelBonus = 1.0 + village.productionBonus;
    return production.scale(levelBonus);
  }

  /// Calculate total consumption for a village this turn.
  ResourceBundle calculateConsumption(Village village) {
    var consumption = ResourceBundle.empty;

    for (final building in village.buildings) {
      consumption = consumption + building.consumption;
    }

    return consumption;
  }

  /// Calculate net resource change (production - consumption).
  ResourceBundle calculateNetChange(Village village) {
    final production = calculateProduction(village);
    final consumption = calculateConsumption(village);
    return production - consumption;
  }

  /// Check if a building can produce this turn.
  bool _canProduce(Building building, ResourceBundle available) {
    return available.canAfford(building.consumption);
  }

  /// Get production modifier based on happiness.
  double _getHappinessModifier(int happiness) {
    if (happiness >= 80) return 1.2; // Very happy: 20% bonus
    if (happiness >= 60) return 1.0; // Content: normal
    if (happiness >= 40) return 0.9; // Unhappy: 10% penalty
    return 0.8; // Very unhappy: 20% penalty
  }

  /// Calculate tax income for a village.
  double calculateTaxIncome(Village village) {
    // Base: 1 gold per population
    var income = village.population.toDouble();

    // Market bonus: +25%
    if (village.hasBuilding(BuildingType.market)) {
      income *= 1.25;
    }

    // Happiness modifier
    final modifier = _getHappinessModifier(village.happiness);
    income *= modifier;

    return income;
  }

  /// Calculate total upkeep cost for units.
  ResourceBundle calculateUnitUpkeep(List<dynamic> units) {
    var total = ResourceBundle.empty;
    for (final unit in units) {
      if (unit.upkeep != null) {
        total = total + (unit.upkeep as ResourceBundle);
      }
    }
    return total;
  }

  /// Calculate population growth for a village.
  PopulationChange calculatePopulationGrowth(Village village) {
    final foodRequired = village.population ~/ 10;
    final foodAvailable = village.resources.food;

    if (foodAvailable < foodRequired) {
      // Starvation
      final loss = (village.population * 0.05).ceil();
      return PopulationChange(
        delta: -loss,
        happinessDelta: -15,
        reason: 'Starvation',
      );
    }

    // Base growth
    var growthRate = 0.05; // 5% base
    var flatBonus = 3;

    // Farm bonus
    final farms = village.buildings.where((b) => b.type == BuildingType.farm);
    for (final _ in farms) {
      flatBonus += 2;
    }

    // Happiness bonus
    if (village.happiness >= 70) {
      growthRate += 0.03;
      flatBonus += 2;
    }

    var growth = (village.population * growthRate).ceil() + flatBonus;

    // Cap at population capacity
    final newPop = (village.population + growth).clamp(0, village.populationCap);
    growth = newPop - village.population;

    return PopulationChange(
      delta: growth,
      happinessDelta: 0,
      reason: growth > 0 ? 'Growth' : 'At capacity',
    );
  }

  /// Calculate happiness change for a village.
  int calculateHappinessChange(Village village) {
    // Target happiness based on conditions
    var targetHappiness = 60; // Base

    // Food surplus
    final foodRequired = village.population ~/ 10;
    if (village.resources.food > village.population ~/ 5) {
      targetHappiness += 10; // Well fed
    } else if (village.resources.food < foodRequired) {
      targetHappiness -= 25; // Starvation
    }

    // Overcrowding
    if (village.population > village.populationCap * 0.9) {
      targetHappiness -= 10;
    }

    // Drift towards target (5 per turn)
    final currentHappiness = village.happiness;
    if (currentHappiness < targetHappiness) {
      return 5.clamp(0, targetHappiness - currentHappiness);
    } else if (currentHappiness > targetHappiness) {
      return -5.clamp(targetHappiness - currentHappiness, 0);
    }
    return 0;
  }

  /// Calculate garrison regeneration.
  int calculateGarrisonRegen(Village village) {
    if (village.underSiege) return 0;

    var recovery = 1;
    if (village.hasBuilding(BuildingType.barracks)) recovery += 1;
    if (village.hasBuilding(BuildingType.fortress)) recovery += 2;

    final maxGarrison = village.computedGarrisonMax;
    final space = maxGarrison - village.garrisonStrength;
    return recovery.clamp(0, space);
  }
}

/// Result of population calculation.
class PopulationChange {
  final int delta;
  final int happinessDelta;
  final String reason;

  const PopulationChange({
    required this.delta,
    required this.happinessDelta,
    required this.reason,
  });
}
