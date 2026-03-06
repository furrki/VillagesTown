import '../data/models/building.dart';
import '../data/models/village.dart';
import '../data/models/village_trait.dart';
import '../data/models/victory_condition.dart';
import '../data/models/resource.dart';
import '../data/models/player.dart';
import '../data/models/ai_personality.dart';
import 'building_construction_engine.dart';
import 'game_manager.dart';

class AIEconomyManager {
  final BuildingConstructionEngine _buildingEngine;

  AIEconomyManager(this._buildingEngine);

  void manageEconomy(Player player, Village village, {VictoryType? victoryGoal}) {
    final game = GameManager.shared;
    final personality = player.aiPersonality ?? AIPersonality.balanced;
    final resources = game.getGlobalResources(player.id);

    // Track what we built this turn to add diversity
    bool builtSomething = false;

    if (village.canBuildMore) {
      // 1. Critical Needs: Emergency farm when food critical
      if ((resources[Resource.food] ?? 0) < 50) {
        if (_tryBuild(village, Building.farm)) {
          builtSomething = true;
        }
      }

      // 2. Victory-aware + trait-aware prioritization
      final priorities = _getVictoryAwarePriorities(personality, village.trait, victoryGoal);

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

    // 3. If no build slots and didn't build, try upgrading
    if (!builtSomething && !village.canBuildMore) {
      _tryUpgrade(village);
    }
  }

  bool _tryUpgrade(Village village) {
    final upgradeable = village.buildings.where((b) => b.level < 5).toList();
    if (upgradeable.isEmpty) return false;
    upgradeable.sort((a, b) => a.level.compareTo(b.level));
    for (final building in upgradeable) {
      if (_buildingEngine.canUpgradeBuilding(building.id, village)) {
        _buildingEngine.upgradeBuilding(building.id, village);
        GameManager.shared.updateVillage(village);
        return true;
      }
    }
    return false;
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

  /// Get priority list adjusted for village trait and AI victory goal.
  List<Building> _getVictoryAwarePriorities(AIPersonality personality, VillageTrait trait, VictoryType? goal) {
    // Start with personality-based priorities
    var base = _getPriorities(personality);

    // Victory goal adjustments: promote buildings that help the goal
    if (goal != null) {
      final goalPromotions = switch (goal) {
        // Economic: markets first
        VictoryType.economic => ['Market', 'Farm'],
        // Military: barracks and military buildings
        VictoryType.military => ['Barracks', 'Iron Mine'],
        // Imperial: economic base for city upgrades
        VictoryType.imperial => ['Farm', 'Market', 'Lumber Mill'],
        // Domination: balanced military + economy
        VictoryType.domination => <String>[],
      };

      if (goalPromotions.isNotEmpty) {
        final promoted = base.where((b) => goalPromotions.contains(b.name)).toList();
        final rest = base.where((b) => !goalPromotions.contains(b.name)).toList();
        base = [...promoted, ...rest];
      }
    }

    // Trait-matching buildings get promoted to front
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
          Building.archeryRange,
          Building.stables,
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
          Building.archeryRange,
          Building.stables,
          Building.fortress,
        ];
      case AIPersonality.balanced:
        return [
          Building.farm,
          Building.market,
          Building.lumberMill,
          Building.ironMine,
          Building.barracks,
          Building.archeryRange,
          Building.stables,
          Building.fortress,
        ];
      case AIPersonality.defensive:
        return [
          Building.fortress,
          Building.barracks,
          Building.archeryRange,
          Building.stables,
          Building.farm,
          Building.market,
          Building.lumberMill,
          Building.ironMine,
        ];
    }
  }
}
