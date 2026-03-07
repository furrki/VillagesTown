import 'mission.dart';

enum CharacterOriginType { exiledNoble, merchantSon, deserter, pilgrim }

class CharacterOrigin {
  final CharacterOriginType type;
  final String title;
  final String description;
  final String shortDescription;
  final int bonusCombat;
  final int bonusLeadership;
  final int bonusTactics;
  final int bonusTrade;
  final int bonusScouting;
  final int bonusGold;
  final int bonusMilitia;
  final int bonusSwordsmen;
  final bool startsWithPackMule;

  const CharacterOrigin({
    required this.type,
    required this.title,
    required this.description,
    required this.shortDescription,
    this.bonusCombat = 0,
    this.bonusLeadership = 0,
    this.bonusTactics = 0,
    this.bonusTrade = 0,
    this.bonusScouting = 0,
    this.bonusGold = 0,
    this.bonusMilitia = 0,
    this.bonusSwordsmen = 0,
    this.startsWithPackMule = false,
  });

  static const exiledNoble = CharacterOrigin(
    type: CharacterOriginType.exiledNoble,
    title: 'Exiled Noble',
    shortDescription: 'Betrayed and cast out, but not broken.',
    description:
        'Your family ruled a prosperous estate until a rival lord seized it '
        'in the night. Your guards were killed, your name disgraced. '
        'You escaped with nothing but your sword arm and a handful of '
        'loyal soldiers. Now you wander the roads, looking for a way '
        'to rebuild what was taken from you.',
    bonusCombat: 1,
    bonusLeadership: 1,
    bonusSwordsmen: 1,
  );

  static const merchantSon = CharacterOrigin(
    type: CharacterOriginType.merchantSon,
    title: "Merchant's Son",
    shortDescription: 'Your father built an empire. Raiders burned it.',
    description:
        'Your father ran caravans between Constantinople and Antioch. '
        'He knew every road, every innkeeper, every customs officer by name. '
        'Then the raiders came. They burned his wagons and left him with nothing. '
        "He died that winter. You inherited his debts, his trade ledger, "
        'and one stubborn pack mule.',
    bonusTrade: 2,
    bonusGold: 50,
    startsWithPackMule: true,
  );

  static const deserter = CharacterOrigin(
    type: CharacterOriginType.deserter,
    title: 'Deserter',
    shortDescription: 'You fled the front lines. They hunt you still.',
    description:
        'Your commander ordered a charge into a wall of spears. '
        'You watched half your company die in minutes. When the horn '
        'sounded for the second charge, you ran. You ran until your '
        'legs gave out, and then you kept walking. Your old comrades '
        'call you coward. You call yourself alive.',
    bonusCombat: 1,
    bonusTactics: 1,
    bonusMilitia: 2,
  );

  static const pilgrim = CharacterOrigin(
    type: CharacterOriginType.pilgrim,
    title: 'Pilgrim',
    shortDescription: 'The holy road hardened you into something else.',
    description:
        'You left home to walk the ancient roads, seeking meaning in '
        'a broken world. The journey taught you to read the land, '
        'to find water where others see dust, to spot danger before '
        'it finds you. Other pilgrims began paying you to walk with them. '
        'Somewhere along the way, the prayer beads became a sword belt.',
    bonusScouting: 1,
    bonusLeadership: 1,
    bonusGold: 30,
  );

  static List<CharacterOrigin> all() =>
      [exiledNoble, merchantSon, deserter, pilgrim];

  /// Create the initial story mission for this origin.
  /// [startCityId] is where the player starts.
  /// [nearestCityId] and [nearestCityName] are a connected neighbor.
  Mission createInitialMission({
    required String startCityId,
    required String nearestCityId,
    required String nearestCityName,
  }) {
    switch (type) {
      case CharacterOriginType.exiledNoble:
        return Mission(
          id: 'origin_noble',
          title: 'A New Beginning',
          description:
              'The tavern keeper eyes your worn coat of arms. '
              '"If you need coin, a merchant needs an escort to $nearestCityName. '
              'Pays well enough for a man with a sword."',
          giverName: 'Tavern Keeper',
          giverCityId: startCityId,
          type: MissionType.story,
          objectives: [
            MissionObjective(
              id: 'noble_travel',
              type: ObjectiveType.travelTo,
              description: 'Travel to $nearestCityName',
              targetCityId: nearestCityId,
            ),
          ],
          goldReward: 40,
        );

      case CharacterOriginType.merchantSon:
        return Mission(
          id: 'origin_merchant',
          title: "Father's Last Ledger",
          description:
              'Among your father\'s belongings, you find an unfinished contract: '
              '"Deliver grain to $nearestCityName." The buyer\'s seal is still fresh. '
              'Honor the old man\'s name.',
          giverName: 'Your Father\'s Memory',
          giverCityId: startCityId,
          type: MissionType.story,
          objectives: [
            MissionObjective(
              id: 'merchant_cargo',
              type: ObjectiveType.haveCargo,
              description: 'Carry 3 grain',
              targetGoodName: 'grain',
              targetAmount: 3,
            ),
            MissionObjective(
              id: 'merchant_deliver',
              type: ObjectiveType.travelTo,
              description: 'Deliver to $nearestCityName',
              targetCityId: nearestCityId,
            ),
          ],
          goldReward: 60,
        );

      case CharacterOriginType.deserter:
        return Mission(
          id: 'origin_deserter',
          title: 'New Roads',
          description:
              'A grizzled trader in the corner lowers his voice. '
              '"You look like a man who needs to disappear. '
              '$nearestCityName is far enough from anyone who might know your face. '
              'I could use a guard on the road."',
          giverName: 'Grizzled Trader',
          giverCityId: startCityId,
          type: MissionType.story,
          objectives: [
            MissionObjective(
              id: 'deserter_travel',
              type: ObjectiveType.travelTo,
              description: 'Travel to $nearestCityName',
              targetCityId: nearestCityId,
            ),
          ],
          goldReward: 35,
        );

      case CharacterOriginType.pilgrim:
        return Mission(
          id: 'origin_pilgrim',
          title: 'The First Step',
          description:
              'An old pilgrim clutches your arm. '
              '"The road to $nearestCityName has become dangerous. '
              'Walk with me, friend. I will pay what I can."',
          giverName: 'Old Pilgrim',
          giverCityId: startCityId,
          type: MissionType.story,
          objectives: [
            MissionObjective(
              id: 'pilgrim_travel',
              type: ObjectiveType.travelTo,
              description: 'Travel to $nearestCityName',
              targetCityId: nearestCityId,
            ),
          ],
          goldReward: 25,
          reputationReward: 5,
        );
    }
  }

  Map<String, dynamic> toJson() => {'type': type.name};

  factory CharacterOrigin.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'exiledNoble';
    return all().firstWhere(
      (o) => o.type.name == typeName,
      orElse: () => exiledNoble,
    );
  }
}
