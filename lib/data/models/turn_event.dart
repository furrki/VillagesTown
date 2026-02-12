import 'resource.dart';

sealed class TurnEvent {
  String get emoji;
  String get message;
  bool get isImportant;
}

class ResourceGainEvent extends TurnEvent {
  final Resource resource;
  final int amount;

  ResourceGainEvent({required this.resource, required this.amount});

  @override
  String get emoji => '📦';

  @override
  String get message => '+$amount ${resource.emoji} ${resource.displayName}';

  @override
  bool get isImportant => false;
}

class ArmySentEvent extends TurnEvent {
  final String armyName;
  final String destination;
  final int turns;

  ArmySentEvent({required this.armyName, required this.destination, required this.turns});

  @override
  String get emoji => '🚶';

  @override
  String get message => '$armyName marching to $destination ($turns turns)';

  @override
  bool get isImportant => false;
}

class ArmyArrivedEvent extends TurnEvent {
  final String armyName;
  final String destination;

  ArmyArrivedEvent({required this.armyName, required this.destination});

  @override
  String get emoji => '🏁';

  @override
  String get message => '$armyName arrived at $destination';

  @override
  bool get isImportant => false;
}

class ArmyArrivedAtEnemyEvent extends TurnEvent {
  final String armyName;
  final String villageName;

  ArmyArrivedAtEnemyEvent({required this.armyName, required this.villageName});

  @override
  String get emoji => '🏰';

  @override
  String get message => '$armyName arrived at $villageName - preparing siege!';

  @override
  bool get isImportant => true;
}

class SiegeStartedEvent extends TurnEvent {
  final String armyName;
  final String villageName;

  SiegeStartedEvent({required this.armyName, required this.villageName});

  @override
  String get emoji => '🏰';

  @override
  String get message => '$armyName besieging $villageName';

  @override
  bool get isImportant => true;
}

class SiegeAssaultEvent extends TurnEvent {
  final String armyName;
  final String villageName;

  SiegeAssaultEvent({required this.armyName, required this.villageName});

  @override
  String get emoji => '⚔️';

  @override
  String get message => '$armyName assaulting $villageName!';

  @override
  bool get isImportant => true;
}

class ArmyInterceptedEvent extends TurnEvent {
  final String army1Name;
  final String army2Name;

  ArmyInterceptedEvent({required this.army1Name, required this.army2Name});

  @override
  String get emoji => '⚔️';

  @override
  String get message => '$army1Name intercepted $army2Name!';

  @override
  bool get isImportant => true;
}

class BattleWonEvent extends TurnEvent {
  final String location;
  final int casualties;

  BattleWonEvent({required this.location, required this.casualties});

  @override
  String get emoji => '⚔️';

  @override
  String get message => 'Victory at $location! Lost $casualties units';

  @override
  bool get isImportant => false;
}

class BattleLostEvent extends TurnEvent {
  final String location;
  final int casualties;

  BattleLostEvent({required this.location, required this.casualties});

  @override
  String get emoji => '💀';

  @override
  String get message => 'Defeat at $location. Lost $casualties units';

  @override
  bool get isImportant => false;
}

class VillageConqueredEvent extends TurnEvent {
  final String villageName;

  VillageConqueredEvent({required this.villageName});

  @override
  String get emoji => '🎉';

  @override
  String get message => '$villageName conquered!';

  @override
  bool get isImportant => true;
}

class VillageLostEvent extends TurnEvent {
  final String villageName;

  VillageLostEvent({required this.villageName});

  @override
  String get emoji => '😢';

  @override
  String get message => '$villageName was lost!';

  @override
  bool get isImportant => true;
}

class EnemyApproachingEvent extends TurnEvent {
  final String enemyName;
  final String target;
  final int turns;
  final int? estimatedSize;

  EnemyApproachingEvent({required this.enemyName, required this.target, required this.turns, this.estimatedSize});

  @override
  String get emoji => '⚠️';

  @override
  String get message {
    final sizeStr = estimatedSize != null ? ' (~$estimatedSize units)' : '';
    return '⚠️ $enemyName approaching $target!$sizeStr $turns turns away';
  }

  @override
  bool get isImportant => true;
}

class EnemyArmySpottedEvent extends TurnEvent {
  final String armyName;
  final String destination;
  final int estimatedSize;

  EnemyArmySpottedEvent({required this.armyName, required this.destination, required this.estimatedSize});

  @override
  String get emoji => '👁️';

  @override
  String get message => 'Enemy $armyName spotted marching to $destination (~$estimatedSize units)';

  @override
  bool get isImportant => false;
}

class GeneralEvent extends TurnEvent {
  final String text;

  GeneralEvent({required this.text});

  @override
  String get emoji => 'ℹ️';

  @override
  String get message => text;

  @override
  bool get isImportant => true;
}
