import '../data/models/player_character.dart';
import '../data/models/trade_good.dart';
import '../data/models/village.dart';
import 'game_manager.dart';

enum PriceTrend { veryCheap, cheap, normal, expensive, veryExpensive }

class TradePrice {
  final TradeGood good;
  final int buyPrice;
  final int sellPrice;
  final int playerOwned;
  final PriceTrend trend;

  const TradePrice({
    required this.good,
    required this.buyPrice,
    required this.sellPrice,
    required this.playerOwned,
    required this.trend,
  });
}

class TradeEngine {
  /// Each unit the player buys raises that city's price by this share, and each unit sold lowers it.
  /// Prices were fixed before, so one good route paid forever: a simulated trader held 21,000 gold
  /// by tick 900 (tool/balance_sim.dart).
  static const pressurePerUnit = 0.015;

  /// Share of the push a city's prices keep after each world turn. A route pays well for about
  /// two runs, then wants a rest.
  static const pressureKept = 0.85;

  static double _pressure(TradeGood good, Village village, [double extra = 0]) =>
      (1 + (GameManager.shared.marketPressure[village.id]?[good] ?? 0) + extra).clamp(0.5, 2.0);

  static void _push(TradeGood good, Village village, double by) {
    final city = GameManager.shared.marketPressure.putIfAbsent(village.id, () => {});
    city[good] = ((city[good] ?? 0) + by).clamp(-0.5, 1.0);
  }

  /// Called once per world turn.
  static void recoverPrices() {
    for (final city in GameManager.shared.marketPressure.values) {
      for (final good in city.keys.toList()) {
        final left = city[good]! * pressureKept;
        if (left.abs() < 0.01) {
          city.remove(good);
        } else {
          city[good] = left;
        }
      }
    }
    GameManager.shared.marketPressure.removeWhere((_, city) => city.isEmpty);
  }

  static int _buyAt(TradeGood good, Village village, double extra) =>
      (good.basePrice * good.priceModifier(village.trait) * _pressure(good, village, extra)).round();

  static int _sellAt(TradeGood good, Village village, double extra) =>
      (good.basePrice * good.priceModifier(village.trait) * 0.8 * _pressure(good, village, extra)).round();

  static int buyPrice(TradeGood good, Village village) => _buyAt(good, village, 0);

  static int sellPrice(TradeGood good, Village village) => _sellAt(good, village, 0);

  static bool buy(TradeGood good, int quantity, PlayerCharacter player, Village village) {
    if (player.currentCargoCount + quantity > player.totalCargoCapacity) return false;
    var total = 0;
    for (var i = 0; i < quantity; i++) {
      total += _buyAt(good, village, i * pressurePerUnit);
    }
    if (player.gold < total) return false;

    player.gold -= total;
    player.addCargo(good, quantity);
    _push(good, village, quantity * pressurePerUnit);
    return true;
  }

  static int sell(TradeGood good, int quantity, PlayerCharacter player, Village village) {
    final owned = player.cargoOf(good);
    if (owned < quantity) return 0;

    var earned = 0;
    for (var i = 0; i < quantity; i++) {
      earned += _sellAt(good, village, -i * pressurePerUnit);
    }
    player.removeCargo(good, quantity);
    _push(good, village, -quantity * pressurePerUnit);
    player.earnGold(earned);
    player.contractsCompleted++;
    if (player.contractsCompleted % 5 == 0) {
      player.tradeSkill = (player.tradeSkill + 1).clamp(1, 20);
    }
    return earned;
  }

  static bool convertToResource(TradeGood good, int quantity, PlayerCharacter player, Village village) {
    final owned = player.cargoOf(good);
    if (owned < quantity) return false;

    final resource = good.convertibleTo;
    if (resource == null) return false;

    player.removeCargo(good, quantity);
    village.resources[resource] = (village.resources[resource] ?? 0) + quantity;
    return true;
  }

  static List<TradePrice> getPrices(Village village, PlayerCharacter player) {
    return TradeGood.values.map((good) {
      final modifier = good.priceModifier(village.trait);
      return TradePrice(
        good: good,
        buyPrice: buyPrice(good, village),
        sellPrice: sellPrice(good, village),
        playerOwned: player.cargoOf(good),
        trend: _trendFromModifier(modifier * _pressure(good, village)),
      );
    }).toList();
  }

  static PriceTrend _trendFromModifier(double modifier) {
    if (modifier < 0.7) return PriceTrend.veryCheap;
    if (modifier < 0.9) return PriceTrend.cheap;
    if (modifier <= 1.1) return PriceTrend.normal;
    if (modifier <= 1.3) return PriceTrend.expensive;
    return PriceTrend.veryExpensive;
  }
}
