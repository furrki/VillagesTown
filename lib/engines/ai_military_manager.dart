import '../data/models/unit_type.dart';
import '../data/models/village.dart';
import '../data/models/victory_condition.dart';
import '../data/models/resource.dart';
import '../data/models/player.dart';
import 'recruitment_engine.dart';
import 'game_manager.dart';

class AIMilitaryManager {
  final RecruitmentEngine _recruitmentEngine;

  AIMilitaryManager(this._recruitmentEngine);

  void manageMilitary(Player player, Village village, {VictoryType? victoryGoal, VictoryType? playerThreat}) {
    final game = GameManager.shared;

    // 1. Require economic foundation before recruiting military
    final economicBuildings = village.buildings.where((b) =>
      b.name == 'Farm' || b.name == 'Market' ||
      b.name == 'Lumber Mill' || b.name == 'Iron Mine'
    ).length;

    // Only recruit if village has at least 2 economic buildings
    if (economicBuildings < 2) return;

    // 2. Check Funding
    final resources = game.getGlobalResources(player.id);
    final gold = resources[Resource.gold] ?? 0;

    // Panic threshold: If under attack (garrison damaged), recruit anyway
    final isUnderThreat = village.garrisonStrength < village.garrisonMaxStrength * 0.8;

    // Victory-aware recruitment threshold
    final minGoldToRecruit = switch (victoryGoal) {
      VictoryType.military => 50,   // More aggressive recruitment
      VictoryType.economic => 200,  // Save gold for economic victory
      VictoryType.imperial => 150,  // Save for city upgrades
      _ => 100,
    };

    if (!isUnderThreat && gold < minGoldToRecruit) return;

    // 3. Determine available units
    final availableUnits = _recruitmentEngine.getAvailableUnits(village);
    if (availableUnits.isEmpty) return;

    // 4. Counter-strategy: recruit more if player is close to winning
    final urgentRecruit = playerThreat != null && playerThreat != VictoryType.military;

    // 5. Recruit with capped amount
    final priority = [
      UnitType.knight,
      UnitType.lightCavalry,
      UnitType.crossbowman,
      UnitType.archer,
      UnitType.swordsman,
      UnitType.spearman,
      UnitType.militia,
    ];

    for (final unit in priority) {
      if (!availableUnits.contains(unit)) continue;

      if (_canAfford(unit, resources, isUnderThreat || urgentRecruit)) {
         int count = 1;
         if (unit == UnitType.militia || unit == UnitType.spearman) count = 3;
         if (unit == UnitType.archer) count = 2;
         // Military victory goal: recruit extra
         if (victoryGoal == VictoryType.military) count += 1;

         final (can, _) = _recruitmentEngine.canRecruit(unit, count, village);
         if (can) {
           _recruitmentEngine.recruitUnits(unit, count, village, village.coordinates);
           return;
         }
         // Fallback: try original count without military bonus
         if (victoryGoal == VictoryType.military && count > 1) {
           count -= 1;
           final (canFallback, _) = _recruitmentEngine.canRecruit(unit, count, village);
           if (canFallback) {
             _recruitmentEngine.recruitUnits(unit, count, village, village.coordinates);
             return;
           }
         }
      }
    }
  }

  bool _canAfford(UnitType unit, Map<Resource, int> currentResources, bool isDesperate) {
    if (isDesperate) return true; // Try to buy anything
    // Logic: Do we have 2x the cost? Buffer for buildings.
    // ...
    return true; // Simple for now
  }
}
