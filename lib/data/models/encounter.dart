import 'dart:math';
import 'geo_coordinate.dart';
import 'trade_good.dart';
import 'unit.dart';
import 'unit_type.dart';

enum EncounterType { bandits, merchant, woundedSoldier, nothing }

class Encounter {
  final EncounterType type;
  final String description;
  final List<Unit>? enemyUnits;
  final int? goldReward;
  final TradeGood? tradeGood;
  final int? tradeGoodAmount;
  final UnitType? recruitableUnit;

  const Encounter({
    required this.type,
    required this.description,
    this.enemyUnits,
    this.goldReward,
    this.tradeGood,
    this.tradeGoodAmount,
    this.recruitableUnit,
  });

  static Encounter generate(int playerStrength, int tickNumber) {
    final rng = Random();
    final roll = rng.nextDouble();

    if (roll < 0.60) {
      return const Encounter(
        type: EncounterType.nothing,
        description: 'The road is quiet.',
      );
    }

    if (roll < 0.85) {
      final count = 3 + rng.nextInt(6) + (tickNumber ~/ 50);
      final bandits = List.generate(
        min(count, 12),
        (_) => Unit(
          name: 'Bandit',
          unitType: UnitType.militia,
          attack: UnitType.militia.stats.attack,
          defense: UnitType.militia.stats.defense,
          maxHP: UnitType.militia.stats.hp,
          currentHP: UnitType.militia.stats.hp,
          movement: UnitType.militia.stats.movement,
          movementRemaining: UnitType.militia.stats.movement,
          owner: 'bandits',
          coordinates: const GeoCoordinate(0, 0),
        ),
      );
      return Encounter(
        type: EncounterType.bandits,
        description: 'Bandits block the road! $count militia attack.',
        enemyUnits: bandits,
        goldReward: 10 + rng.nextInt(20),
      );
    }

    if (roll < 0.95) {
      final good = TradeGood.values[rng.nextInt(TradeGood.values.length)];
      return Encounter(
        type: EncounterType.merchant,
        description: 'A traveling merchant offers ${good.displayName}.',
        tradeGood: good,
        tradeGoodAmount: 5,
        goldReward: (good.basePrice * 0.9).round(),
      );
    }

    const infantryTypes = [
      UnitType.militia,
      UnitType.spearman,
      UnitType.swordsman,
    ];
    final unitType = infantryTypes[rng.nextInt(infantryTypes.length)];
    return Encounter(
      type: EncounterType.woundedSoldier,
      description:
          'A wounded ${unitType.displayName} asks to join your warband.',
      recruitableUnit: unitType,
    );
  }
}
