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
    final priorities = _getPriorities(personality, village);

    for (final building in priorities) {
      // Don't build duplicates unless allowed (Farms/Mines usually scaled by level, but here unique list)
      // Actually our Building model is templates. 
      // Current engine check: if (village.buildings.any((b) => b.name == building.name)) continue;
      // We should check if we already have it. If so, maybe UPGRADE?
      // For MVP, if we have it, skip (unless upgrade logic added later).
      
      if (village.hasBuilding(building.name)) {
        // Upgrade logic could go here
        final existing = village.getBuilding(building.name);
        if (existing != null && existing.level < 5) {
           // Try upgrade?
           // _buildingEngine.canUpgrade(existing, ...)
           // For now, let's Stick to new buildings first to fill slots.
        }
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

  List<Building> _getPriorities(AIPersonality personality, Village village) {
    // Dynamic priorities based on what we lack?
    // For now, static lists per personality are a good start, but ordered smarter.
    
    final base = [
      Building.market,      // Gold is king
      Building.ironMine,    // Weapons
      Building.lumberMill,  // Construction
      Building.barracks,    // Defense
      Building.farm,        // Population
      Building.fortress,    // Late game defense
    ];

    switch (personality) {
      case AIPersonality.aggressive:
        return [
          Building.ironMine,
          Building.barracks,
          Building.forges, // Assuming we have this? If not, ignored.
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
      default:
        return base;
    }
  }
}
