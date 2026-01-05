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
    // 1. Check Funding
    // Don't spend if we are saving for a critical building (handled by balanced biases usually, 
    // but here we just check if we have "disposable" income or if we are desperate).
    
    final resources = GameManager.shared.getGlobalResources(player.id);
    final gold = resources[Resource.gold] ?? 0;
    
    // Panic threshold: If under attack (garrison damaged), spend everything.
    final isUnderThreat = village.garrisonStrength < village.garrisonMaxStrength * 0.8;
    
    if (!isUnderThreat && gold < 100) return; // Save up checks

    // 2. Determine Needs
    final availableUnits = _recruitmentEngine.getAvailableUnits(village);
    if (availableUnits.isEmpty) return;

    // 3. Recruit Smarter
    // Mix units. Don't just buy the first one.
    // Order: Cavalry > Ranged > Infantry (Quality over Quantity?)
    // Or Balanced: 1 Cav, 2 Arch, 3 Inf.
    
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

      // Affordability check
      if (_canAfford(unit, resources, isUnderThreat)) {
         // Recruit batch
         int count = 1;
         if (unit == UnitType.militia || unit == UnitType.spearman) count = 5; // Bulk recruit fodder
         if (unit == UnitType.archer) count = 3;

         final (can, _) = _recruitmentEngine.canRecruit(unit, count, village);
         if (can) {
           _recruitmentEngine.recruitUnits(unit, count, village, village.coordinates);
           // Decrement resources locally to prevent overspending in loop? 
           // recruitmentEngine does it on Shared GameManager, so next loop 'resources' is stale unless we fetch again.
           // For simplicity, we break after one successful recruit action per turn per village.
           return; 
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
