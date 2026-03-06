import '../data/models/player_character.dart';
import '../data/models/trade_good.dart';
import '../data/models/village.dart';

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
  static int buyPrice(TradeGood good, Village village, {int marketTaxPercent = 0, PlayerCharacter? player}) {
    final modifier = good.priceModifier(village.trait);
    final discount = player != null ? (1.0 - player.tradeDiscount).clamp(0.7, 1.0) : 1.0;
    return (good.basePrice * modifier * discount * (1 + marketTaxPercent / 100)).round();
  }

  static int sellPrice(TradeGood good, Village village) {
    final modifier = good.priceModifier(village.trait);
    return (good.basePrice * modifier * 0.8).round();
  }

  static bool buy(TradeGood good, int quantity, PlayerCharacter player, Village village) {
    final total = buyPrice(good, village) * quantity;
    if (player.gold < total) return false;
    if (player.currentCargoCount + quantity > player.totalCargoCapacity) return false;

    player.gold -= total;
    player.addCargo(good, quantity);
    return true;
  }

  static int sell(TradeGood good, int quantity, PlayerCharacter player, Village village) {
    final owned = player.cargoOf(good);
    if (owned < quantity) return 0;

    final earned = sellPrice(good, village) * quantity;
    player.removeCargo(good, quantity);
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
        trend: _trendFromModifier(modifier),
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
