enum GameEventType {
  // Duration events (modify game state for N turns)
  drought,
  harshWinter,
  bountifulHarvest,
  goldRush,
  royalMarriage,
  crusadeCalled,

  // Instant events (one-time effects)
  earthquake,
  tradeCaravan,
  rebellion,
  civilWar,
  mercenaryCompany,
}

class GameEvent {
  final String id;
  final GameEventType type;
  final int triggerTurn;
  final int duration; // 0 = instant
  int turnsRemaining;
  final String? targetVillageId;
  final String? targetPlayerId;
  final String? secondaryPlayerId;
  bool isActive;

  GameEvent({
    required this.id,
    required this.type,
    required this.triggerTurn,
    this.duration = 0,
    int? turnsRemaining,
    this.targetVillageId,
    this.targetPlayerId,
    this.secondaryPlayerId,
    this.isActive = true,
  }) : turnsRemaining = turnsRemaining ?? duration;

  bool get isExpired => duration > 0 && turnsRemaining <= 0;
  bool get isInstant => duration == 0;

  String get emoji => switch (type) {
        GameEventType.drought => '☀️',
        GameEventType.harshWinter => '❄️',
        GameEventType.bountifulHarvest => '🌾',
        GameEventType.goldRush => '💰',
        GameEventType.royalMarriage => '💍',
        GameEventType.crusadeCalled => '✝️',
        GameEventType.earthquake => '🌍',
        GameEventType.tradeCaravan => '🐪',
        GameEventType.rebellion => '🔥',
        GameEventType.civilWar => '⚔️',
        GameEventType.mercenaryCompany => '🗡️',
      };

  String get displayName => switch (type) {
        GameEventType.drought => 'Drought',
        GameEventType.harshWinter => 'Harsh Winter',
        GameEventType.bountifulHarvest => 'Bountiful Harvest',
        GameEventType.goldRush => 'Gold Rush',
        GameEventType.royalMarriage => 'Royal Marriage',
        GameEventType.crusadeCalled => 'Crusade Called',
        GameEventType.earthquake => 'Earthquake',
        GameEventType.tradeCaravan => 'Trade Caravan',
        GameEventType.rebellion => 'Rebellion',
        GameEventType.civilWar => 'Civil War',
        GameEventType.mercenaryCompany => 'Mercenary Company',
      };
}
