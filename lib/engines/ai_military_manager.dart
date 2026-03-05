import '../data/models/unit_type.dart';
import '../data/models/village.dart';
import '../data/models/victory_condition.dart';
import '../data/models/resource.dart';
import '../data/models/player.dart';
import '../data/models/ai_personality.dart';
import 'recruitment_engine.dart';
import 'game_manager.dart';
import 'victory_engine.dart';

class AIMilitaryManager {
  final RecruitmentEngine _recruitmentEngine;

  AIMilitaryManager(this._recruitmentEngine);

  void manageMilitary(Player player, Village village) {
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
    final victoryGoal = _getBestVictoryGoal(game, player);
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
    final playerThreat = _assessPlayerThreat(game);
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
      }
    }
  }

  VictoryType? _getBestVictoryGoal(GameManager game, Player player) {
    final progresses = VictoryEngine.getAllProgress(game, player.id);
    VictoryType? best;
    double bestScore = -1;
    final personality = player.aiPersonality ?? AIPersonality.balanced;
    for (final p in progresses) {
      double weight = p.progress;
      weight *= switch (p.type) {
        VictoryType.domination => personality.expansionBias,
        VictoryType.economic => personality.economicBias,
        VictoryType.military => personality.aggressionBias,
        VictoryType.imperial => personality.economicBias * 0.8,
      };
      if (weight > bestScore) {
        bestScore = weight;
        best = p.type;
      }
    }
    return best;
  }

  VictoryType? _assessPlayerThreat(GameManager game) {
    final progresses = VictoryEngine.getAllProgress(game, 'player');
    for (final p in progresses) {
      if (p.progress >= 0.7) return p.type;
    }
    return null;
  }

  bool _canAfford(UnitType unit, Map<Resource, int> currentResources, bool isDesperate) {
    if (isDesperate) return true; // Try to buy anything
    // Logic: Do we have 2x the cost? Buffer for buildings.
    // ...
    return true; // Simple for now
  }
}
