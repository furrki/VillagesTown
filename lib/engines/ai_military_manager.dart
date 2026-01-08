import '../data/models/unit_type.dart';
import '../data/models/village.dart';
import '../data/models/resource.dart';
import '../data/models/player.dart';
import 'recruitment_engine.dart';
import 'game_manager.dart';

class AIMilitaryManager {
  final RecruitmentEngine _recruitmentEngine;

  AIMilitaryManager(this._recruitmentEngine);

  void manageMilitary(Player player, Village village) {
    // 1. Require economic foundation before recruiting military
    // Count economic buildings (farm, market, lumberMill, ironMine)
    final economicBuildings = village.buildings.where((b) =>
      b.name == 'Farm' || b.name == 'Market' ||
      b.name == 'Lumber Mill' || b.name == 'Iron Mine'
    ).length;

    // Only recruit if village has at least 2 economic buildings
    if (economicBuildings < 2) return;

    // 2. Check Funding
    final resources = GameManager.shared.getGlobalResources(player.id);
    final gold = resources[Resource.gold] ?? 0;

    // Panic threshold: If under attack (garrison damaged), recruit anyway
    final isUnderThreat = village.garrisonStrength < village.garrisonMaxStrength * 0.8;

    if (!isUnderThreat && gold < 100) return;

    // 3. Determine available units
    final availableUnits = _recruitmentEngine.getAvailableUnits(village);
    if (availableUnits.isEmpty) return;

    // 4. Recruit with capped amount (max 3 units per turn per village)
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

      if (_canAfford(unit, resources, isUnderThreat)) {
         // Cap recruitment: max 3 units per turn (was 5 for militia)
         int count = 1;
         if (unit == UnitType.militia || unit == UnitType.spearman) count = 3;
         if (unit == UnitType.archer) count = 2;

         final (can, _) = _recruitmentEngine.canRecruit(unit, count, village);
         if (can) {
           _recruitmentEngine.recruitUnits(unit, count, village, village.coordinates);
           return; // One recruit action per turn per village
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
