import '../data/models/building.dart';
import '../data/models/game_modifier.dart';
import '../data/models/resource.dart';
import '../data/models/village.dart';
import 'game_manager.dart';

class BuildingConstructionEngine {
  Map<Resource, int> buildCost(Building building) {
    final cost = Map<Resource, int>.from(building.baseCost);
    if (GameManager.shared.activeModifiers.contains(GameModifier.goldStandard) && cost.containsKey(Resource.gold)) {
      cost[Resource.gold] = cost[Resource.gold]! * 2;
    }
    return cost;
  }

  Map<Resource, int> upgradeCostFor(Building building) {
    final cost = getUpgradeCost(building);
    if (GameManager.shared.activeModifiers.contains(GameModifier.goldStandard) && cost.containsKey(Resource.gold)) {
      cost[Resource.gold] = cost[Resource.gold]! * 2;
    }
    return cost;
  }

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

    final cost = buildCost(building);

    if (!game.canAfford(village.owner, cost)) {
      return (false, 'Insufficient resources');
    }

    return (true, '');
  }

  bool buildBuilding(Building building, Village village) {
    final (can, _) = canBuild(building, village);
    if (!can) return false;

    final game = GameManager.shared;
    final cost = buildCost(building);
    game.spendResources(village.owner, cost);
    village.addBuilding(building.copyWith());
    game.updateVillage(village);
    return true;
  }

  bool canUpgradeBuilding(String buildingId, Village village) {
    final building = village.buildings.where((b) => b.id == buildingId).firstOrNull;
    if (building == null) return false;
    if (building.level >= 5) return false;

    final cost = upgradeCostFor(building);
    final game = GameManager.shared;
    return game.canAfford(village.owner, cost);
  }

  bool upgradeBuilding(String buildingId, Village village) {
    final buildingIndex = village.buildings.indexWhere((b) => b.id == buildingId);
    if (buildingIndex == -1) return false;

    final building = village.buildings[buildingIndex];
    if (building.level >= 5) return false;

    final cost = upgradeCostFor(building);
    final game = GameManager.shared;

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
