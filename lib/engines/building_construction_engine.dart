import '../data/models/building.dart';
import '../data/models/game_modifier.dart';
import '../data/models/resource.dart';
import '../data/models/village.dart';
import 'game_manager.dart';

class BuildingConstructionEngine {
  (bool can, String reason) canBuild(Building building, Village village) {
    if (!village.canBuildMore) {
      return (false, 'No building slots available');
    }

    if (village.buildings.any((b) => b.name == building.name)) {
      return (false, 'Building already exists');
    }

    final game = GameManager.shared;

    // No Fortress modifier
    if (building.name == 'Fortress' && game.activeModifiers.contains(GameModifier.noFortress)) {
      return (false, 'Fortresses disabled');
    }

    // Gold Standard modifier: double gold costs
    var cost = building.baseCost;
    if (game.activeModifiers.contains(GameModifier.goldStandard)) {
      cost = Map.from(cost);
      if (cost.containsKey(Resource.gold)) {
        cost[Resource.gold] = (cost[Resource.gold]! * 2);
      }
    }

    if (!game.canAfford(village.owner, cost)) {
      return (false, 'Insufficient resources');
    }

    return (true, '');
  }

  bool buildBuilding(Building building, Village village) {
    final (can, _) = canBuild(building, village);
    if (!can) return false;

    final game = GameManager.shared;
    var cost = building.baseCost;
    if (game.activeModifiers.contains(GameModifier.goldStandard)) {
      cost = Map.from(cost);
      if (cost.containsKey(Resource.gold)) {
        cost[Resource.gold] = (cost[Resource.gold]! * 2);
      }
    }
    game.spendResources(village.owner, cost);
    village.addBuilding(building.copyWith());
    game.updateVillage(village);
    return true;
  }

  bool canUpgradeBuilding(String buildingId, Village village) {
    final building = village.buildings.cast<Building?>().firstWhere(
          (b) => b!.id == buildingId,
          orElse: () => null,
        );
    if (building == null) return false;
    if (building.level >= 5) return false;

    var cost = getUpgradeCost(building);
    final game = GameManager.shared;
    if (game.activeModifiers.contains(GameModifier.goldStandard)) {
      cost = Map.from(cost);
      if (cost.containsKey(Resource.gold)) {
        cost[Resource.gold] = (cost[Resource.gold]! * 2);
      }
    }
    return game.canAfford(village.owner, cost);
  }

  bool upgradeBuilding(String buildingId, Village village) {
    final buildingIndex = village.buildings.indexWhere((b) => b.id == buildingId);
    if (buildingIndex == -1) return false;

    final building = village.buildings[buildingIndex];
    if (building.level >= 5) return false;

    var cost = getUpgradeCost(building);
    final game = GameManager.shared;
    if (game.activeModifiers.contains(GameModifier.goldStandard)) {
      cost = Map.from(cost);
      if (cost.containsKey(Resource.gold)) {
        cost[Resource.gold] = (cost[Resource.gold]! * 2);
      }
    }

    if (!game.spendResources(village.owner, cost)) return false;

    // Upgrade the building
    village.buildings[buildingIndex] = building.copyWith(level: building.level + 1);
    game.updateVillage(village);
    return true;
  }

  Map<Resource, int> getUpgradeCost(Building building) {
    final multiplier = 1.5;
    return building.baseCost.map(
      (key, value) => MapEntry(key, (value * multiplier * building.level).round()),
    );
  }
}
