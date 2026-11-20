import 'package:flutter_test/flutter_test.dart';
import 'package:villages_town/data/models/mission.dart';
import 'package:villages_town/data/models/nationality.dart';
import 'package:villages_town/data/models/player_character.dart';
import 'package:villages_town/data/models/trade_good.dart';
import 'package:villages_town/engines/contract_board.dart';
import 'package:villages_town/engines/game_manager.dart';
import 'package:villages_town/engines/trade_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('a delivery pays once only when the cargo reaches its destination', () {
    final game = GameManager.shared..resetGame()..setupGame(Nationality.ottomans);
    final city = game.map.villages.firstWhere((v) => game.getNeighbors(v.id).isNotEmpty);
    game.playerCharacter = PlayerCharacter(name: 'Test', currentCityId: city.id, gold: 10000);
    game.absorbPurse();
    final player = game.playerCharacter!;
    final offer = ContractBoard.offersFor(city, game).single;
    expect(ContractBoard.offersFor(city, game).single.toJson(), offer.toJson());
    expect(ContractBoard.accept(offer, game), isTrue);
    expect(ContractBoard.accept(ContractBoard.offersFor(city, game).single, game), isFalse);
    final cargo = offer.objectives.firstWhere((o) => o.type == ObjectiveType.haveCargo);
    final destination = offer.objectives.firstWhere((o) => o.type == ObjectiveType.travelTo).targetCityId!;
    final good = TradeGood.values.byName(cargo.targetGoodName!);
    expect(TradeEngine.buy(good, cargo.targetAmount, player, city), isTrue);
    game.checkMissions();
    player.removeCargo(good, cargo.targetAmount);
    game.checkMissions(destination);
    expect(player.activeMissions, contains(offer));
    expect(TradeEngine.buy(good, cargo.targetAmount, player, city), isTrue);
    final before = game.gold;
    game.checkMissions(destination);
    expect(game.gold, before + offer.goldReward);
    expect(player.completedMissions, contains(offer));
    expect(player.activeMissions, isNot(contains(offer)));
    game.checkMissions(destination);
    expect(game.gold, before + offer.goldReward);
    game.resetGame();
  });
}
