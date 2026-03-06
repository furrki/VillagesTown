import 'dart:math';
import 'package:uuid/uuid.dart';
import '../data/models/game_event.dart';
import '../data/models/nationality.dart';
import '../data/models/resource.dart';
import '../data/models/turn_event.dart';
import '../data/models/unit.dart';
import '../data/models/unit_type.dart';
import 'game_manager.dart';

class EventEngine {
  static final _rand = Random();
  static const _uuid = Uuid();

  /// Called each turn from turn_engine, between Economy and Population phases.
  static void processEvents(GameManager game) {
    _tickActiveEvents(game);
    _rollForNewEvents(game);
  }

  // --- Tick down active duration events ---
  static void _tickActiveEvents(GameManager game) {
    final toRemove = <String>[];
    for (final event in game.activeEvents) {
      if (event.duration > 0 && event.isActive) {
        event.turnsRemaining--;
        if (event.turnsRemaining <= 0) {
          event.isActive = false;
          toRemove.add(event.id);
          game.addTurnEvent(WorldEventEndedEvent(eventName: event.displayName));
        }
      }
    }
    game.activeEvents.removeWhere((e) => toRemove.contains(e.id));
  }

  // --- Roll for new events based on turn and probabilities ---
  static void _rollForNewEvents(GameManager game) {
    final turn = game.currentTurn;

    // Don't fire events in the first few turns
    if (turn < 5) return;

    // Max 1 new event per turn to avoid overwhelming the player
    bool eventFiredThisTurn = false;

    // Conditional events (checked every turn)
    if (!eventFiredThisTurn) eventFiredThisTurn = _checkRebellion(game);

    // Duration events (random roll within turn range)
    if (!eventFiredThisTurn && _inRange(turn, 5, 25) && _roll(0.08)) {
      if (!_hasActiveType(game, GameEventType.bountifulHarvest) &&
          !_hasActiveType(game, GameEventType.drought)) {
        _fireBountifulHarvest(game);
        eventFiredThisTurn = true;
      }
    }

    if (!eventFiredThisTurn && _inRange(turn, 8, 40) && _roll(0.06)) {
      if (!_hasUsedOneTime(game, GameEventType.drought) &&
          !_hasActiveType(game, GameEventType.bountifulHarvest)) {
        _fireDrought(game);
        eventFiredThisTurn = true;
      }
    }

    if (!eventFiredThisTurn && _inRange(turn, 10, 45) && _roll(0.07)) {
      if (_countType(game, GameEventType.harshWinter) < 2 &&
          !_hasActiveType(game, GameEventType.harshWinter)) {
        _fireHarshWinter(game);
        eventFiredThisTurn = true;
      }
    }

    if (!eventFiredThisTurn && _inRange(turn, 10, 35) && _roll(0.06)) {
      if (_countType(game, GameEventType.goldRush) < 2) {
        _fireGoldRush(game);
        eventFiredThisTurn = true;
      }
    }

    if (!eventFiredThisTurn && _inRange(turn, 15, 35) && _roll(0.05)) {
      if (_countType(game, GameEventType.royalMarriage) < 2) {
        _fireRoyalMarriage(game);
        eventFiredThisTurn = true;
      }
    }

    if (!eventFiredThisTurn && _inRange(turn, 20, 50) && _roll(0.04)) {
      _checkCrusadeCalled(game);
      // Don't set eventFiredThisTurn - crusade is conditional
    }

    // Instant events
    if (!eventFiredThisTurn && _inRange(turn, 10, 999) && _roll(0.05)) {
      _fireEarthquake(game);
      eventFiredThisTurn = true;
    }

    if (!eventFiredThisTurn && _inRange(turn, 5, 30) && _roll(0.09)) {
      _fireTradeCaravan(game);
      eventFiredThisTurn = true;
    }

    if (!eventFiredThisTurn && _inRange(turn, 12, 40) && _roll(0.06)) {
      if (_countType(game, GameEventType.mercenaryCompany) < 3) {
        _fireMercenaryCompany(game);
        eventFiredThisTurn = true;
      }
    }

    if (!eventFiredThisTurn && _inRange(turn, 25, 50) && _roll(0.04)) {
      if (!_hasUsedOneTime(game, GameEventType.civilWar)) {
        _fireCivilWar(game);
        eventFiredThisTurn = true;
      }
    }
  }

  // === DURATION EVENTS ===

  static void _fireDrought(GameManager game) {
    final event = GameEvent(
      id: _uuid.v4(),
      type: GameEventType.drought,
      triggerTurn: game.currentTurn,
      duration: 3,
    );
    game.activeEvents.add(event);
    game.eventHistory.add(event);
    game.addTurnEvent(WorldEventStartedEvent(
      eventName: 'Drought',
      emoji: '☀️',
      description: 'A great drought spreads across the land. Farm output halved for 3 turns.',
      duration: 3,
    ));
  }

  static void _fireHarshWinter(GameManager game) {
    final event = GameEvent(
      id: _uuid.v4(),
      type: GameEventType.harshWinter,
      triggerTurn: game.currentTurn,
      duration: 3,
    );
    game.activeEvents.add(event);
    game.eventHistory.add(event);
    game.addTurnEvent(WorldEventStartedEvent(
      eventName: 'Harsh Winter',
      emoji: '❄️',
      description: 'Winter descends. All army movement takes +1 extra turn for 3 turns.',
      duration: 3,
    ));
  }

  static void _fireBountifulHarvest(GameManager game) {
    final event = GameEvent(
      id: _uuid.v4(),
      type: GameEventType.bountifulHarvest,
      triggerTurn: game.currentTurn,
      duration: 2,
    );
    game.activeEvents.add(event);
    game.eventHistory.add(event);
    game.addTurnEvent(WorldEventStartedEvent(
      eventName: 'Bountiful Harvest',
      emoji: '🌾',
      description: 'The harvest is abundant! Farms produce double food for 2 turns.',
      duration: 2,
    ));
  }

  static void _fireGoldRush(GameManager game) {
    // Pick a random village that has a market
    final candidates = game.map.villages
        .where((v) => v.owner != 'neutral' && v.buildings.any((b) => b.name == 'Market'))
        .toList();
    if (candidates.isEmpty) return;

    final target = candidates[_rand.nextInt(candidates.length)];
    final event = GameEvent(
      id: _uuid.v4(),
      type: GameEventType.goldRush,
      triggerTurn: game.currentTurn,
      duration: 5,
      targetVillageId: target.id,
      targetPlayerId: target.owner,
    );
    game.activeEvents.add(event);
    game.eventHistory.add(event);
    game.addTurnEvent(WorldEventStartedEvent(
      eventName: 'Gold Rush',
      emoji: '💰',
      description: 'Gold deposits found near ${game.getVillageDisplayName(target)}! 3x gold production for 5 turns.',
      duration: 5,
    ));
  }

  static void _fireRoyalMarriage(GameManager game) {
    // Pick two non-eliminated AI players who aren't already in a pact
    final aiPlayers = game.players
        .where((p) => !p.isHuman && !p.isEliminated)
        .toList();
    if (aiPlayers.length < 2) return;

    aiPlayers.shuffle(_rand);
    final player1 = aiPlayers[0];
    final player2 = aiPlayers[1];

    // Check they don't already have an active pact
    if (hasNonAggressionPact(game, player1.id, player2.id)) return;

    final event = GameEvent(
      id: _uuid.v4(),
      type: GameEventType.royalMarriage,
      triggerTurn: game.currentTurn,
      duration: 10,
      targetPlayerId: player1.id,
      secondaryPlayerId: player2.id,
    );
    game.activeEvents.add(event);
    game.eventHistory.add(event);
    game.addTurnEvent(WorldEventStartedEvent(
      eventName: 'Royal Marriage',
      emoji: '💍',
      description: '${player1.name} and ${player2.name} form a marriage alliance! 10 turns of peace between them.',
      duration: 10,
    ));
  }

  static void _checkCrusadeCalled(GameManager game) {
    if (_hasUsedOneTime(game, GameEventType.crusadeCalled)) return;

    // Check if Crusader faction is losing (owns < 2 villages)
    final crusaderPlayer = game.players.firstWhere(
      (p) => p.nationality == Nationality.crusaders && !p.isEliminated,
      orElse: () => game.players.first,
    );
    if (crusaderPlayer.isEliminated) return;

    final crusaderVillages = game.getPlayerVillages(crusaderPlayer.id);
    if (crusaderVillages.length >= 2) return; // Not losing

    final event = GameEvent(
      id: _uuid.v4(),
      type: GameEventType.crusadeCalled,
      triggerTurn: game.currentTurn,
      duration: 5,
      targetPlayerId: crusaderPlayer.id,
    );
    game.activeEvents.add(event);
    game.eventHistory.add(event);
    game.addTurnEvent(WorldEventStartedEvent(
      eventName: 'Crusade Called',
      emoji: '✝️',
      description: 'A new Crusade is called! Crusader armies gain +10% attack for 5 turns.',
      duration: 5,
    ));
  }

  // === INSTANT EVENTS ===

  static void _fireEarthquake(GameManager game) {
    // Pick a random non-neutral village
    final candidates = game.map.villages.where((v) => v.owner != 'neutral' && v.buildings.isNotEmpty).toList();
    if (candidates.isEmpty) return;

    final target = candidates[_rand.nextInt(candidates.length)];

    // Remove a random building (prefer non-essential)
    final nonFortress = target.buildings.where((b) => b.name != 'Fortress').toList();
    final buildingsToTarget = nonFortress.isNotEmpty ? nonFortress : target.buildings;
    if (buildingsToTarget.isEmpty) return;

    final destroyed = buildingsToTarget[_rand.nextInt(buildingsToTarget.length)];
    target.buildings.remove(destroyed);

    // Downgrade fortress if exists
    final fortress = target.buildings.where((b) => b.name == 'Fortress').toList();
    if (fortress.isNotEmpty && fortress.first.level > 1) {
      final idx = target.buildings.indexOf(fortress.first);
      target.buildings[idx] = fortress.first.copyWith(level: fortress.first.level - 1);
    }

    game.updateVillage(target);

    final event = GameEvent(
      id: _uuid.v4(),
      type: GameEventType.earthquake,
      triggerTurn: game.currentTurn,
      targetVillageId: target.id,
      targetPlayerId: target.owner,
    );
    game.eventHistory.add(event);
    game.addTurnEvent(WorldEventStartedEvent(
      eventName: 'Earthquake',
      emoji: '🌍',
      description: 'An earthquake strikes ${game.getVillageDisplayName(target)}! ${destroyed.name} destroyed.',
      duration: 0,
    ));
  }

  static void _fireTradeCaravan(GameManager game) {
    // Pick a random owned village and give the owner bonus resources
    final candidates = game.map.villages.where((v) => v.owner != 'neutral').toList();
    if (candidates.isEmpty) return;

    final target = candidates[_rand.nextInt(candidates.length)];
    game.modifyGlobalResource(target.owner, Resource.gold, 500);
    game.modifyGlobalResource(target.owner, Resource.food, 200);

    final event = GameEvent(
      id: _uuid.v4(),
      type: GameEventType.tradeCaravan,
      triggerTurn: game.currentTurn,
      targetVillageId: target.id,
      targetPlayerId: target.owner,
    );
    game.eventHistory.add(event);

    if (target.owner == 'player') {
      game.addTurnEvent(WorldEventStartedEvent(
        eventName: 'Trade Caravan',
        emoji: '🐪',
        description: 'A wealthy caravan arrives at ${game.getVillageDisplayName(target)}! +500 gold, +200 food.',
        duration: 0,
      ));
    } else {
      game.addTurnEvent(WorldEventStartedEvent(
        eventName: 'Trade Caravan',
        emoji: '🐪',
        description: 'A trade caravan passes through enemy territory near ${game.getVillageDisplayName(target)}.',
        duration: 0,
      ));
    }
  }

  static bool _checkRebellion(GameManager game) {
    // Check all owned villages for unhappiness
    for (final village in game.map.villages) {
      if (village.owner == 'neutral') continue;
      if (village.happiness >= 20) continue;

      // 15% chance per turn when unhappy
      if (!_roll(0.15)) continue;

      final oldOwner = village.owner;
      village.owner = 'neutral';
      village.garrisonStrength = 5;
      village.happiness = 50; // Reset happiness
      game.updateVillage(village);

      // Remove stationed armies
      final armiesHere = game.getArmiesAt(village.id)
          .where((a) => a.owner == oldOwner)
          .toList();
      for (final army in armiesHere) {
        game.removeArmy(army.id);
      }

      final event = GameEvent(
        id: _uuid.v4(),
        type: GameEventType.rebellion,
        triggerTurn: game.currentTurn,
        targetVillageId: village.id,
        targetPlayerId: oldOwner,
      );
      game.eventHistory.add(event);

      if (oldOwner == 'player') {
        game.addTurnEvent(WorldEventStartedEvent(
          eventName: 'Rebellion',
          emoji: '🔥',
          description: '${game.getVillageDisplayName(village)} rises in revolt! The people reject your rule.',
          duration: 0,
        ));
      } else {
        game.addTurnEvent(WorldEventStartedEvent(
          eventName: 'Rebellion',
          emoji: '🔥',
          description: 'Rebellion erupts in ${game.getVillageDisplayName(village)}! It breaks free from its ruler.',
          duration: 0,
        ));
      }
      return true;
    }
    return false;
  }

  static void _fireCivilWar(GameManager game) {
    // Find the player with the most villages
    final activePlayers = game.players.where((p) => !p.isEliminated).toList();
    if (activePlayers.length < 2) return;

    activePlayers.sort((a, b) =>
        game.getPlayerVillages(b.id).length.compareTo(game.getPlayerVillages(a.id).length));

    final leader = activePlayers.first;
    final leaderVillages = game.getPlayerVillages(leader.id);
    if (leaderVillages.length < 3) return; // Need at least 3 to lose one

    final secondPlace = activePlayers[1];

    // Find weakest village (lowest garrison + population)
    leaderVillages.sort((a, b) =>
        (a.garrisonStrength + a.population).compareTo(b.garrisonStrength + b.population));
    final weakest = leaderVillages.first;

    // Defect to second place
    weakest.owner = secondPlace.id;
    weakest.happiness = max(30, weakest.happiness - 15);
    game.updateVillage(weakest);

    // Remove leader's armies at that village
    final armiesHere = game.getArmiesAt(weakest.id)
        .where((a) => a.owner == leader.id)
        .toList();
    for (final army in armiesHere) {
      game.removeArmy(army.id);
    }

    final event = GameEvent(
      id: _uuid.v4(),
      type: GameEventType.civilWar,
      triggerTurn: game.currentTurn,
      targetVillageId: weakest.id,
      targetPlayerId: leader.id,
      secondaryPlayerId: secondPlace.id,
    );
    game.eventHistory.add(event);

    game.addTurnEvent(WorldEventStartedEvent(
      eventName: 'Civil War',
      emoji: '⚔️',
      description: 'A succession crisis! ${game.getVillageDisplayName(weakest)} defects from ${leader.name} to ${secondPlace.name}.',
      duration: 0,
    ));
  }

  static void _fireMercenaryCompany(GameManager game) {
    // Spawn mercenary army at a random player's capital (first village)
    final activePlayers = game.players.where((p) => !p.isEliminated).toList();
    if (activePlayers.isEmpty) return;

    final lucky = activePlayers[_rand.nextInt(activePlayers.length)];
    final villages = game.getPlayerVillages(lucky.id);
    if (villages.isEmpty) return;

    final spawnVillage = villages.first;

    // Create mercenary units: 3 swordsmen + 2 archers + 1 knight
    final units = <Unit>[
      ...List.generate(3, (_) => Unit.create(UnitType.swordsman, lucky.id, spawnVillage.coordinates)),
      ...List.generate(2, (_) => Unit.create(UnitType.archer, lucky.id, spawnVillage.coordinates)),
      Unit.create(UnitType.knight, lucky.id, spawnVillage.coordinates),
    ];

    game.createArmy(units, spawnVillage.id, lucky.id);
    game.mergeArmiesAt(spawnVillage.id, lucky.id);

    final event = GameEvent(
      id: _uuid.v4(),
      type: GameEventType.mercenaryCompany,
      triggerTurn: game.currentTurn,
      targetVillageId: spawnVillage.id,
      targetPlayerId: lucky.id,
    );
    game.eventHistory.add(event);

    if (lucky.id == 'player') {
      game.addTurnEvent(WorldEventStartedEvent(
        eventName: 'Mercenary Company',
        emoji: '🗡️',
        description: 'A Free Company offers their swords! 3 swordsmen, 2 archers, and a knight join your forces at ${game.getVillageDisplayName(spawnVillage)}.',
        duration: 0,
      ));
    } else {
      game.addTurnEvent(WorldEventStartedEvent(
        eventName: 'Mercenary Company',
        emoji: '🗡️',
        description: 'Mercenaries have joined ${lucky.name} at ${game.getVillageDisplayName(spawnVillage)}.',
        duration: 0,
      ));
    }
  }

  // === MODIFIER QUERIES (called by other engines) ===

  /// Food production multiplier from active events.
  static double foodProductionModifier(GameManager game) {
    double mod = 1.0;
    for (final event in game.activeEvents) {
      if (!event.isActive) continue;
      if (event.type == GameEventType.drought) mod *= 0.5;
      if (event.type == GameEventType.bountifulHarvest) mod *= 2.0;
    }
    return mod;
  }

  /// Gold production multiplier for a specific village from Gold Rush.
  static double goldProductionModifier(GameManager game, String villageId) {
    for (final event in game.activeEvents) {
      if (!event.isActive) continue;
      if (event.type == GameEventType.goldRush && event.targetVillageId == villageId) {
        return 3.0;
      }
    }
    return 1.0;
  }

  /// Extra movement turns from Harsh Winter.
  static int movementPenalty(GameManager game) {
    for (final event in game.activeEvents) {
      if (!event.isActive) continue;
      if (event.type == GameEventType.harshWinter) return 1;
    }
    return 0;
  }

  /// Check if two players have a non-aggression pact (Royal Marriage).
  static bool hasNonAggressionPact(GameManager game, String player1, String player2) {
    for (final event in game.activeEvents) {
      if (!event.isActive) continue;
      if (event.type != GameEventType.royalMarriage) continue;
      if ((event.targetPlayerId == player1 && event.secondaryPlayerId == player2) ||
          (event.targetPlayerId == player2 && event.secondaryPlayerId == player1)) {
        return true;
      }
    }
    return false;
  }

  /// Check if Crusade is active for a player (attack bonus).
  static bool isCrusadeActive(GameManager game, String playerId) {
    for (final event in game.activeEvents) {
      if (!event.isActive) continue;
      if (event.type == GameEventType.crusadeCalled && event.targetPlayerId == playerId) {
        return true;
      }
    }
    return false;
  }

  // === HELPERS ===

  static bool _roll(double probability) => _rand.nextDouble() < probability;
  static bool _inRange(int turn, int minTurn, int maxTurn) => turn >= minTurn && turn <= maxTurn;
  static bool _hasActiveType(GameManager game, GameEventType type) =>
      game.activeEvents.any((e) => e.type == type && e.isActive);
  static bool _hasUsedOneTime(GameManager game, GameEventType type) =>
      game.eventHistory.any((e) => e.type == type);
  static int _countType(GameManager game, GameEventType type) =>
      game.eventHistory.where((e) => e.type == type).length;
}
