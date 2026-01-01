import 'dart:math';
import '../data/models/resource.dart';
import '../data/models/village.dart';
import 'game_manager.dart';

class PopulationEngine {
  void processPopulationGrowth(List<Village> villages) {
    for (var i = 0; i < villages.length; i++) {
      var village = villages[i];
      if (village.owner == 'neutral') continue;

      // Check food availability
      final foodNeeded = village.population ~/ 10;
      final hasFood = village.getResource(Resource.food) >= foodNeeded;

      if (hasFood) {
        village.subtractResource(Resource.food, foodNeeded);

        // Base growth: 5% + flat bonus
        var growthRate = 0.05;
        var flatBonus = 3;

        // Happiness bonuses
        if (village.happiness >= 70) {
          growthRate += 0.03;
          flatBonus += 2;
        } else if (village.happiness < 40) {
          growthRate -= 0.02;
        }

        // Farm bonus
        final farmCount = village.buildings.where((b) => b.name == 'Farm').length;
        flatBonus += farmCount * 2;

        // Granary bonus
        if (village.buildings.any((b) => b.name == 'Granary')) {
          growthRate += 0.02;
        }

        final growth = (village.population * growthRate).round() + flatBonus;
        village.modifyPopulation(growth);
      } else {
        // Starvation
        final loss = (village.population * 0.05).round();
        village.modifyPopulation(-loss);
        village.modifyHappiness(-15);
      }

      villages[i] = village;
    }
  }

  void collectTaxes(List<Village> villages) {
    final game = GameManager.shared;

    for (var i = 0; i < villages.length; i++) {
      final village = villages[i];
      if (village.owner == 'neutral') continue;

      // 1 gold per population
      var tax = village.population;

      // Market bonus +25%
      if (village.buildings.any((b) => b.name == 'Market')) {
        tax = (tax * 1.25).round();
      }

      game.modifyGlobalResource(village.owner, Resource.gold, tax);
    }
  }

  void processHappiness(List<Village> villages) {
    for (var i = 0; i < villages.length; i++) {
      var village = villages[i];
      if (village.owner == 'neutral') continue;

      // Baseline happiness tends toward 60
      var targetHappiness = 60;

      // Food surplus increases target
      if (village.getResource(Resource.food) > village.population ~/ 5) {
        targetHappiness += 10;
      }

      // Starvation decreases it severely
      if (village.getResource(Resource.food) < village.population ~/ 10) {
        targetHappiness -= 25;
      }

      // Overcrowding
      if (village.population > village.populationCapacity * 0.9) {
        targetHappiness -= 10;
      }

      // Drift toward target
      if (village.happiness < targetHappiness) {
        village.modifyHappiness(min(5, targetHappiness - village.happiness));
      } else if (village.happiness > targetHappiness) {
        village.modifyHappiness(-min(5, village.happiness - targetHappiness));
      }

      villages[i] = village;
    }
  }
}
