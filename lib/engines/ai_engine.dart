import '../data/map/game_map.dart';
import '../data/models/ai_personality.dart';
import '../data/models/player.dart';
import '../data/models/victory_condition.dart';
import 'building_construction_engine.dart';
import 'game_manager.dart';
import 'recruitment_engine.dart';
import 'victory_engine.dart';
import 'ai_economy_manager.dart';
import 'ai_military_manager.dart';
import 'ai_strategy_manager.dart';

class AIEngine {
  late final AIEconomyManager _economyManager;
  late final AIMilitaryManager _militaryManager;
  late final AIStrategyManager _strategyManager;

  AIEngine() {
    final buildingEngine = BuildingConstructionEngine();
    final recruitmentEngine = RecruitmentEngine();

    _economyManager = AIEconomyManager(buildingEngine);
    _militaryManager = AIMilitaryManager(recruitmentEngine);
    _strategyManager = AIStrategyManager();
  }

  static VictoryType? getBestVictoryGoal(GameManager game, Player player) {
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

  static VictoryType? assessPlayerThreat(GameManager game) {
    final progresses = VictoryEngine.getAllProgress(game, 'player');
    for (final p in progresses) {
      if (p.progress >= 0.7) return p.type;
    }
    return null;
  }

  void executeAITurn(Player player, GameMap map) {
    if (player.isHuman) return;

    final game = GameManager.shared;
    final villages = map.villages.where((v) => v.owner == player.id).toList();
    if (villages.isEmpty) return;

    final victoryGoal = getBestVictoryGoal(game, player);
    final playerThreat = assessPlayerThreat(game);

    // 1. Economy Phase (Build, Upgrade)
    for (final village in villages) {
      _economyManager.manageEconomy(player, village, victoryGoal: victoryGoal);
    }

    // 2. Military Phase (Recruit)
    for (final village in villages) {
      _militaryManager.manageMilitary(player, village, victoryGoal: victoryGoal, playerThreat: playerThreat);
    }

    // 3. Strategy Phase (Move, Attack)
    _strategyManager.manageStrategy(player, map, victoryGoal: victoryGoal, playerThreat: playerThreat);
  }
}

