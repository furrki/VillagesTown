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
  test('a delivery takes its goods and pays once only at the destination', () {
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
    final wrongCity = game.map.villages.firstWhere((v) => v.id != destination && v.id != city.id).id;
    final good = TradeGood.values.byName(cargo.targetGoodName!);
    expect(TradeEngine.buy(good, cargo.targetAmount - 1, player, city), isTrue);
    final before = game.gold;
    game.checkMissions(destination);
    expect(player.cargoOf(good), cargo.targetAmount - 1);
    expect(game.gold, before);
    expect(TradeEngine.buy(good, 2, player, city), isTrue);
    final carried = player.cargoOf(good);
    game.checkMissions(wrongCity);
    expect(player.cargoOf(good), carried);
    expect(player.activeMissions, contains(offer));
    final paidFrom = game.gold;
    game.checkMissions(destination);
    expect(player.cargoOf(good), carried - cargo.targetAmount);
    expect(game.gold, paidFrom + offer.goldReward);
    expect(player.completedMissions, contains(offer));
    expect(player.activeMissions, isNot(contains(offer)));
    game.checkMissions(destination);
    expect(player.cargoOf(good), carried - cargo.targetAmount);
    expect(game.gold, paidFrom + offer.goldReward);
    game.resetGame();
  });
}
