import 'dart:math';

import '../data/models/mission.dart';
import '../data/models/trade_good.dart';
import '../data/models/village.dart';
import 'game_manager.dart';
import 'trade_engine.dart';

class ContractBoard {
  static List<Mission> offersFor(Village city, GameManager game) {
    final neighbors = game.getNeighbors(city.id)..sort((a, b) => a.id.compareTo(b.id));
    if (neighbors.isEmpty) return [];
    final good = TradeGood.values.reduce((a, b) =>
        TradeEngine.buyPrice(b, city) > TradeEngine.buyPrice(a, city) ? b : a);
    final destination = neighbors.reduce((a, b) =>
        TradeEngine.sellPrice(good, b) > TradeEngine.sellPrice(good, a) ? b : a);
    final amount = city.buildings.any((b) => b.name == 'Market') ? 5 : 3;
    final reward = max(25, (TradeEngine.sellPrice(good, destination) -
            TradeEngine.buyPrice(good, city)) * amount + 25);
    final id = 'contract_${city.id}_${game.currentTurn}';
    return [Mission(
      id: id,
      title: 'Delivery to ${game.getVillageDisplayName(destination)}',
      description: 'Bring $amount ${good.displayName} to ${game.getVillageDisplayName(destination)}.',
      giverName: 'Townsfolk', giverCityId: city.id, type: MissionType.delivery,
      goldReward: reward, expiresAtTick: game.gameLoop.tickCount + 120,
      objectives: [
        MissionObjective(id: '${id}_cargo', type: ObjectiveType.haveCargo,
            description: 'Carry $amount ${good.displayName}', targetGoodName: good.name, targetAmount: amount),
        MissionObjective(id: '${id}_travel', type: ObjectiveType.travelTo,
            description: 'Travel to ${game.getVillageDisplayName(destination)}', targetCityId: destination.id),
      ],
    )];
  }

  static bool accept(Mission mission, GameManager game) {
    final player = game.playerCharacter;
    if (player == null || alreadyAccepted(mission, game)) return false;
    player.activeMissions.add(mission);
    game.refreshUI();
    return true;
  }

  static bool alreadyAccepted(Mission mission, GameManager game) {
    final player = game.playerCharacter;
    if (player == null) return false;
    return [...player.activeMissions, ...player.completedMissions].any((m) =>
        m.type == MissionType.delivery && m.giverCityId == mission.giverCityId &&
        m.id.startsWith('contract_') && m.id.endsWith('_${game.currentTurn}'));
  }
}
