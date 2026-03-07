import 'dart:math';
import 'geo_coordinate.dart';
import 'trade_good.dart';
import 'unit.dart';
import 'unit_type.dart';

enum EncounterType { bandits, merchant, woundedSoldier, nothing, deserters, refugees, patrol }

enum EncounterChoiceOutcome {
  fight,
  flee,
  payGold,
  gainGold,
  gainCargo,
  recruitUnit,
  dismiss,
  loseGold,
  loseCargo,
  gainReputation,
}

class EncounterChoice {
  final String label;
  final String? skillRequired;
  final int skillLevel;
  final EncounterChoiceOutcome outcome;
  final String resultText;
  final int? goldAmount;
  final TradeGood? tradeGood;
  final int? tradeGoodAmount;
  final UnitType? unitType;

  const EncounterChoice({
    required this.label,
    this.skillRequired,
    this.skillLevel = 0,
    required this.outcome,
    required this.resultText,
    this.goldAmount,
    this.tradeGood,
    this.tradeGoodAmount,
    this.unitType,
  });

  bool isAvailable(Map<String, int> skills) {
    if (skillRequired == null) return true;
    return (skills[skillRequired] ?? 1) >= skillLevel;
  }
}

class Encounter {
  final EncounterType type;
  final String narrative;
  final List<EncounterChoice> choices;
  final List<Unit>? enemyUnits;
  final int? goldReward;
  final TradeGood? tradeGood;
  final int? tradeGoodAmount;
  final UnitType? recruitableUnit;

  const Encounter({
    required this.type,
    required this.narrative,
    this.choices = const [],
    this.enemyUnits,
    this.goldReward,
    this.tradeGood,
    this.tradeGoodAmount,
    this.recruitableUnit,
  });

  // Legacy getter for backward compat
  String get description => narrative;

  static Encounter generate(int playerStrength, int tickNumber) {
    final rng = Random();
    final roll = rng.nextDouble();

    if (roll < 0.50) {
      return const Encounter(
        type: EncounterType.nothing,
        narrative: 'The road is quiet.',
      );
    }

    if (roll < 0.72) {
      return _generateBandits(rng, playerStrength, tickNumber);
    }

    if (roll < 0.82) {
      return _generateDeserters(rng, tickNumber);
    }

    if (roll < 0.90) {
      return _generateMerchant(rng);
    }

    if (roll < 0.96) {
      return _generateRefugees(rng);
    }

    return _generateWoundedSoldier(rng);
  }

  static Encounter _generateBandits(Random rng, int playerStrength, int tickNumber) {
    final count = 3 + rng.nextInt(6) + (tickNumber ~/ 50);
    final actualCount = min(count, 12);
    final bandits = List.generate(
      actualCount,
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

    final tollCost = 15 + rng.nextInt(20);
    final loot = 10 + rng.nextInt(25);

    final narratives = [
      'A group of armed men emerge from the tree line. Their leader, a scarred man missing an ear, raises his hand. "$actualCount of us, and we\'re hungry. Pay the toll or we take what we want."',
      'Shadows move in the brush ahead. Before you can react, $actualCount rough-looking men surround your party. "Nice cargo you have there," one grins.',
      'A makeshift barricade blocks the road. Behind it, $actualCount bandits watch you approach. Their leader steps forward, axe resting on his shoulder.',
      'You hear a whistle from the hillside. Figures rise from behind rocks on both sides of the road. $actualCount bandits. You\'re boxed in.',
    ];

    return Encounter(
      type: EncounterType.bandits,
      narrative: narratives[rng.nextInt(narratives.length)],
      enemyUnits: bandits,
      goldReward: loot,
      choices: [
        EncounterChoice(
          label: 'Fight',
          outcome: EncounterChoiceOutcome.fight,
          resultText: 'You draw your sword and charge.',
        ),
        EncounterChoice(
          label: 'Pay toll (${tollCost}g)',
          outcome: EncounterChoiceOutcome.payGold,
          goldAmount: tollCost,
          resultText: 'You toss a purse of coins. They count it and wave you through.',
        ),
        EncounterChoice(
          label: 'Intimidate',
          skillRequired: 'combat',
          skillLevel: 3,
          outcome: EncounterChoiceOutcome.dismiss,
          resultText: 'You step forward slowly, hand on your blade. The leader reads your eyes and decides this isn\'t worth dying over. They melt back into the trees.',
        ),
        EncounterChoice(
          label: 'Flee',
          outcome: EncounterChoiceOutcome.flee,
          resultText: 'You spur your horse and scatter cargo behind you. They grab what they can and let you go.',
        ),
      ],
    );
  }

  static Encounter _generateDeserters(Random rng, int tickNumber) {
    final count = 4 + rng.nextInt(5);
    final deserters = List.generate(
      count,
      (_) => Unit(
        name: 'Deserter',
        unitType: rng.nextBool() ? UnitType.militia : UnitType.spearman,
        attack: UnitType.militia.stats.attack + 1,
        defense: UnitType.militia.stats.defense + 1,
        maxHP: UnitType.militia.stats.hp,
        currentHP: UnitType.militia.stats.hp,
        movement: UnitType.militia.stats.movement,
        movementRemaining: UnitType.militia.stats.movement,
        owner: 'bandits',
        coordinates: const GeoCoordinate(0, 0),
      ),
    );

    final narratives = [
      'A group of soldiers sits by the roadside, their uniforms torn and muddied. They\'ve deserted from a losing campaign. Their sergeant looks up at you with hollow eyes. "We can fight for you, or we can fight you. Your choice."',
      'Armed men block the road, but they\'re not bandits. Their armor is too good, their discipline too familiar. Deserters from a recent battle, looking for a new paymaster.',
    ];

    return Encounter(
      type: EncounterType.deserters,
      narrative: narratives[rng.nextInt(narratives.length)],
      enemyUnits: deserters,
      goldReward: 15 + rng.nextInt(15),
      recruitableUnit: UnitType.spearman,
      choices: [
        EncounterChoice(
          label: 'Recruit them',
          skillRequired: 'leadership',
          skillLevel: 2,
          outcome: EncounterChoiceOutcome.recruitUnit,
          unitType: UnitType.spearman,
          resultText: 'You offer them purpose and pay. They fall in line. Soldiers follow strength.',
        ),
        EncounterChoice(
          label: 'Fight',
          outcome: EncounterChoiceOutcome.fight,
          resultText: 'They chose wrong. You draw steel.',
        ),
        EncounterChoice(
          label: 'Let them pass',
          outcome: EncounterChoiceOutcome.dismiss,
          resultText: 'You step aside. They nod and continue down the road. Not your problem.',
        ),
      ],
    );
  }

  static Encounter _generateMerchant(Random rng) {
    final good = TradeGood.values[rng.nextInt(TradeGood.values.length)];
    final amount = 3 + rng.nextInt(5);
    final price = (good.basePrice * (0.6 + rng.nextDouble() * 0.4)).round();

    final narratives = [
      'A merchant caravan has stopped to rest by the road. The caravan master waves you over. "Looking to trade? I have ${good.displayName} at a fair price. $amount units for ${price}g each."',
      'An old trader leading a mule loaded with goods flags you down. "Friend! I\'m heading the wrong way for this cargo. ${good.displayName}, $amount units. ${price}g each and they\'re yours."',
      'A well-guarded wagon sits by the roadside, its merchant leaning against a wheel, smoking. He eyes your warband and grins. "I could use fewer things to protect. ${good.displayName}? ${price}g per unit."',
    ];

    return Encounter(
      type: EncounterType.merchant,
      narrative: narratives[rng.nextInt(narratives.length)],
      tradeGood: good,
      tradeGoodAmount: amount,
      goldReward: price,
      choices: [
        EncounterChoice(
          label: 'Buy $amount ${good.displayName} (${price * amount}g)',
          outcome: EncounterChoiceOutcome.gainCargo,
          tradeGood: good,
          tradeGoodAmount: amount,
          goldAmount: price * amount,
          resultText: 'You count out the coins. Good trade.',
        ),
        EncounterChoice(
          label: 'Haggle',
          skillRequired: 'trade',
          skillLevel: 3,
          outcome: EncounterChoiceOutcome.gainCargo,
          tradeGood: good,
          tradeGoodAmount: amount,
          goldAmount: (price * amount * 0.7).round(),
          resultText: 'After some back and forth, he agrees to a lower price. Your reputation precedes you.',
        ),
        EncounterChoice(
          label: 'Decline',
          outcome: EncounterChoiceOutcome.dismiss,
          resultText: 'You wave him off. The road calls.',
        ),
      ],
    );
  }

  static Encounter _generateRefugees(Random rng) {
    final goldAmount = 10 + rng.nextInt(10);

    final narratives = [
      'A family huddles by the roadside. A woman holds a crying child while a man stands guard with a broken spear. "Please," she says. "We haven\'t eaten in days. The soldiers took everything."',
      'A line of refugees trudges toward you, carrying what little they could save. An elder at the front stops. "Kind traveler, any food you could spare? The war has taken our village."',
    ];

    return Encounter(
      type: EncounterType.refugees,
      narrative: narratives[rng.nextInt(narratives.length)],
      choices: [
        EncounterChoice(
          label: 'Give food',
          outcome: EncounterChoiceOutcome.loseCargo,
          tradeGood: TradeGood.grain,
          tradeGoodAmount: 2,
          resultText: 'You hand over what you can spare. The woman\'s eyes fill with tears. "God will remember this." Word of your kindness will spread.',
        ),
        EncounterChoice(
          label: 'Give gold (${goldAmount}g)',
          outcome: EncounterChoiceOutcome.payGold,
          goldAmount: goldAmount,
          resultText: 'You press coins into the elder\'s hand. He bows deeply. "We will pray for your safe journey."',
        ),
        EncounterChoice(
          label: 'Move on',
          outcome: EncounterChoiceOutcome.dismiss,
          resultText: 'You avert your eyes and keep walking. You can\'t save everyone.',
        ),
      ],
    );
  }

  static Encounter _generateWoundedSoldier(Random rng) {
    const infantryTypes = [
      UnitType.militia,
      UnitType.spearman,
      UnitType.swordsman,
    ];
    final unitType = infantryTypes[rng.nextInt(infantryTypes.length)];

    final narratives = [
      'A soldier sits against a tree, clutching a wound in his side. His armor marks him as a ${unitType.displayName}. "My company was wiped out," he gasps. "I can still fight. Take me with you, or leave me for the wolves."',
      'You find a ${unitType.displayName} limping down the road, using his weapon as a crutch. He sees your warband and straightens up. "I need a company. You need a soldier. Simple as that."',
    ];

    return Encounter(
      type: EncounterType.woundedSoldier,
      narrative: narratives[rng.nextInt(narratives.length)],
      recruitableUnit: unitType,
      choices: [
        EncounterChoice(
          label: 'Take him in',
          outcome: EncounterChoiceOutcome.recruitUnit,
          unitType: unitType,
          resultText: 'He grits his teeth and falls in with your warband. Another sword at your side.',
        ),
        EncounterChoice(
          label: 'Give him gold and move on',
          outcome: EncounterChoiceOutcome.payGold,
          goldAmount: 5,
          resultText: 'You toss him a few coins. "Find an inn. Get that wound cleaned." He nods.',
        ),
        EncounterChoice(
          label: 'Leave him',
          outcome: EncounterChoiceOutcome.dismiss,
          resultText: 'You walk past. He watches you go without a word.',
        ),
      ],
    );
  }
}
