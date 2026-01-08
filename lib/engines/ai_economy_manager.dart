import '../data/models/building.dart';
import '../data/models/village.dart';
import '../data/models/resource.dart';
import '../data/models/player.dart';
import '../data/models/ai_personality.dart';
import 'building_construction_engine.dart';
import 'game_manager.dart';

class AIEconomyManager {
  final BuildingConstructionEngine _buildingEngine;

  AIEconomyManager(this._buildingEngine);

  void manageEconomy(Player player, Village village) {
    if (!village.canBuildMore) return;

    final personality = player.aiPersonality ?? AIPersonality.balanced;
    final resources = GameManager.shared.getGlobalResources(player.id);

    // Track what we built this turn to add diversity
    bool builtSomething = false;

    // 1. Critical Needs Assessment
    // If food is low, try to build farms (but don't exit early!)
    if ((resources[Resource.food] ?? 0) < 50) {
      if (_tryBuild(village, Building.farm)) {
        builtSomething = true;
        // Don't return - continue trying other buildings
      }
    }

    // 2. Personality-based prioritization
    final priorities = _getPriorities(personality);

    for (final building in priorities) {
      // Skip if already built
      if (village.buildings.any((b) => b.name == building.name)) {
        continue;
      }

      // Skip if we already built something this turn (one build per turn)
      if (builtSomething) break;

      if (_tryBuild(village, building)) {
        builtSomething = true;
        break; // One successful build per call
      }
    }
  }

  bool _tryBuild(Village village, Building template) {
    final (can, _) = _buildingEngine.canBuild(template, village);
    if (can) {
      _buildingEngine.buildBuilding(template, village);
      GameManager.shared.updateVillage(village);
      return true;
    }
    return false;
  }

  /// Get distinct priority list per personality (no duplicates)
  List<Building> _getPriorities(AIPersonality personality) {
    switch (personality) {
      case AIPersonality.aggressive:
        return [
          Building.ironMine,
          Building.barracks,
          Building.market,
          Building.lumberMill,
          Building.farm,
          Building.fortress,
        ];
      case AIPersonality.economic:
        return [
          Building.market,
          Building.farm,
          Building.lumberMill,
          Building.ironMine,
          Building.barracks,
          Building.fortress,
        ];
      case AIPersonality.balanced:
        return [
          Building.farm,
          Building.market,
          Building.lumberMill,
          Building.ironMine,
          Building.barracks,
          Building.fortress,
        ];
      case AIPersonality.defensive:
        return [
          Building.fortress,
          Building.barracks,
          Building.farm,
          Building.market,
          Building.lumberMill,
          Building.ironMine,
        ];
    }
  }
}
