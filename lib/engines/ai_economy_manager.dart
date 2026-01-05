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

    // 1. Critical Needs Assessment
    // If food is low, panic build farms
    if ((resources[Resource.food] ?? 0) < 50) {
      if (_tryBuild(village, Building.farm)) return;
    }

    // 2. Personality-based prioritization
    final priorities = _getPriorities(personality);

    for (final building in priorities) {
      // Skip if already built
      if (village.buildings.any((b) => b.name == building.name)) {
        continue;
      }

      if (_tryBuild(village, building)) return;
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

  List<Building> _getPriorities(AIPersonality personality) {
    final base = [
      Building.market,
      Building.ironMine,
      Building.lumberMill,
      Building.barracks,
      Building.farm,
      Building.fortress,
    ];

    switch (personality) {
      case AIPersonality.aggressive:
        return [
          Building.ironMine,
          Building.barracks,
          Building.market,
          ...base,
        ];
      case AIPersonality.economic:
        return [
          Building.market,
          Building.farm,
          Building.lumberMill,
          Building.ironMine,
          ...base,
        ];
      case AIPersonality.balanced:
        return base;
    }
  }
}
