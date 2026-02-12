import '../data/models/building.dart';
import '../data/models/village.dart';
import '../data/models/village_trait.dart';
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

    // 1. Critical Needs: Emergency farm when food critical
    if ((resources[Resource.food] ?? 0) < 50) {
      if (_tryBuild(village, Building.farm)) {
        builtSomething = true;
      }
    }

    // 2. Trait-aware prioritization: boost buildings matching village trait
    final priorities = _getTraitAwarePriorities(personality, village.trait);

    for (final building in priorities) {
      if (village.buildings.any((b) => b.name == building.name)) {
        continue;
      }
      if (builtSomething) break;

      if (_tryBuild(village, building)) {
        builtSomething = true;
        break;
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

  /// Get priority list adjusted for village trait.
  /// Trait-matching buildings get promoted to front of list.
  List<Building> _getTraitAwarePriorities(AIPersonality personality, VillageTrait trait) {
    final base = _getPriorities(personality);

    // Promote trait-matching building to front
    final traitBuilding = switch (trait) {
      VillageTrait.fertile => 'Farm',
      VillageTrait.forested => 'Lumber Mill',
      VillageTrait.mountainous => 'Iron Mine',
      VillageTrait.tradeCrossroads => 'Market',
      VillageTrait.coastal => 'Market',
      VillageTrait.strategic => 'Fortress',
      VillageTrait.none => null,
    };

    if (traitBuilding == null) return base;

    final promoted = base.where((b) => b.name == traitBuilding).toList();
    final rest = base.where((b) => b.name != traitBuilding).toList();
    return [...promoted, ...rest];
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
