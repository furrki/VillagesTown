import '../data/map/game_map.dart';
import '../data/models/player.dart';
import 'building_construction_engine.dart';
import 'recruitment_engine.dart';
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

  void executeAITurn(Player player, GameMap map) {
    if (player.isHuman) return;

    final villages = map.villages.where((v) => v.owner == player.id).toList();
    if (villages.isEmpty) return;

    // 1. Economy Phase (Build, Upgrade)
    for (final village in villages) {
      _economyManager.manageEconomy(player, village);
    }

    // 2. Military Phase (Recruit)
    // Refresh villages list? Not strictly needed unless economy expanded borders (not possible in this MVP)
    for (final village in villages) {
      _militaryManager.manageMilitary(player, village);
    }

    // 3. Strategy Phase (Move, Attack)
    _strategyManager.manageStrategy(player, map);
  }
}

