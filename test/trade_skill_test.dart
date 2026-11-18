import 'package:flutter_test/flutter_test.dart';
import 'package:villages_town/data/models/nationality.dart';
import 'package:villages_town/data/models/player_character.dart';
import 'package:villages_town/data/models/trade_good.dart';
import 'package:villages_town/engines/game_manager.dart';
import 'package:villages_town/engines/trade_engine.dart';

void main() {
  test('trade skill changes prices and sales count separately from contracts', () {
    final game = GameManager.shared..resetGame();
    game.setupGame(Nationality.ottomans);
    final city = game.map.villages.first;
    final low = PlayerCharacter(name: 'Low', tradeSkill: 1, gold: 10000);
    final high = PlayerCharacter(name: 'High', tradeSkill: 11, gold: 10000);
    final good = TradeGood.values.first;
    final lowPrice = TradeEngine.getPrices(city, low).firstWhere((p) => p.good == good);
    final highPrice = TradeEngine.getPrices(city, high).firstWhere((p) => p.good == good);
    expect(highPrice.buyPrice, lessThanOrEqualTo(lowPrice.buyPrice * 0.9));
    expect(highPrice.sellPrice, lowPrice.sellPrice);
    for (final p in TradeEngine.getPrices(city, high)) {
      expect(p.sellPrice, lessThan(p.buyPrice), reason: '${p.good.name} buys and sells back at a profit');
    }
    expect(TradeEngine.buy(good, 1, high, city), isTrue);
    expect(10000 - high.gold, highPrice.buyPrice);
    high.addCargo(good, 1);
    final shownSell = TradeEngine.getPrices(city, high).firstWhere((p) => p.good == good).sellPrice;
    expect(TradeEngine.sell(good, 1, high, city), shownSell);
    TradeEngine.sell(good, 1, high, city);
    expect(high.contractsCompleted, 0);
    expect(high.salesCompleted, 2);
    expect(PlayerCharacter.fromJson(high.toJson()).salesCompleted, 2);
    final oldSave = high.toJson()..remove('salesCompleted');
    expect(PlayerCharacter.fromJson(oldSave).salesCompleted, 0);
    game.resetGame();
  });
}
