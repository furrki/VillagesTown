import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../core/constants/game_constants.dart';
import '../data/map/game_map.dart';
import '../data/map/virtual_map.dart';
import '../data/models/army.dart';
import '../data/models/nationality.dart';
import '../data/models/player.dart';
import '../data/models/resource.dart';
import '../data/models/turn_event.dart';
import '../data/models/unit.dart';
import '../data/models/unit_type.dart';
import '../data/models/village.dart';
import 'turn_engine.dart';

class GameManager extends ChangeNotifier {
  static final GameManager _instance = GameManager._internal();
  static GameManager get shared => _instance;
  factory GameManager() => _instance;
  GameManager._internal() {
    map = VirtualMap(
      size: Size(GameConstants.mapWidth.toDouble(), GameConstants.mapHeight.toDouble()),
      villages: [],
    );
  }

  // State
  late GameMap map;
  List<Player> players = Player.createPlayers();
  int currentTurn = 0;
  String currentPlayer = 'player';
  bool gameStarted = false;
  Nationality? playerNationality;
  Nationality? ai1Nationality;
  Nationality? ai2Nationality;

  late final TurnEngine turnEngine = TurnEngine();

  Map<String, Map<Resource, int>> globalResources = {};
  List<Army> armies = [];
  List<TurnEvent> turnEvents = [];
  Set<String> discoveredVillageIDs = {};
  double visionRange = GameConstants.visionRange;

  bool tutorialEnabled = true;
  int tutorialStep = 0;

  void setupGame(Nationality nationality) {
    playerNationality = nationality;
    final nationalities = Nationality.getAll();

    // Find AI nationalities (excluding player's choice)
    final aiNationalities = nationalities.where((n) => n.name != nationality.name).toList()..shuffle();

    ai1Nationality = aiNationalities[0];
    ai2Nationality = aiNationalities.length > 1 ? aiNationalities[1] : aiNationalities[0];

    // Update player nationalities
    players[0] = players[0].copyWith(nationality: playerNationality);
    players[1] = players[1].copyWith(nationality: ai1Nationality);
    players[2] = players[2].copyWith(nationality: ai2Nationality);

    // Player village
    final playerVillage = Village(
      name: _getCapitalName(nationality),
      nationality: nationality,
      coordinates: const Offset(3, 3),
      owner: 'player',
    );

    final ai1Village = Village(
      name: _getCapitalName(ai1Nationality!),
      nationality: ai1Nationality!,
      coordinates: const Offset(17, 3),
      owner: 'ai1',
    );

    final ai2Village = Village(
      name: _getCapitalName(ai2Nationality!),
      nationality: ai2Nationality!,
      coordinates: const Offset(10, 17),
      owner: 'ai2',
    );

    // Neutral villages
    final neutralVillages = [
      Village(name: 'Thessaloniki', nationality: nationalities[1], coordinates: const Offset(10, 2), owner: 'neutral'),
      Village(name: 'Alexandroupoli', nationality: nationalities[1], coordinates: const Offset(14, 4), owner: 'neutral'),
      Village(name: 'Kavala', nationality: nationalities[1], coordinates: const Offset(2, 10), owner: 'neutral'),
      Village(name: 'Ioannina', nationality: nationalities[1], coordinates: const Offset(5, 7), owner: 'neutral'),
      Village(name: 'Edirne', nationality: nationalities[0], coordinates: const Offset(8, 8), owner: 'neutral'),
      Village(name: 'Bursa', nationality: nationalities[0], coordinates: const Offset(12, 10), owner: 'neutral'),
      Village(name: 'Plovdiv', nationality: nationalities[2], coordinates: const Offset(10, 13), owner: 'neutral'),
      Village(name: 'Varna', nationality: nationalities[2], coordinates: const Offset(18, 8), owner: 'neutral'),
      Village(name: 'Constanta', nationality: nationalities[2], coordinates: const Offset(16, 14), owner: 'neutral'),
      Village(name: 'Izmir', nationality: nationalities[0], coordinates: const Offset(6, 15), owner: 'neutral'),
      Village(name: 'Antalya', nationality: nationalities[0], coordinates: const Offset(14, 18), owner: 'neutral'),
      Village(name: 'Patras', nationality: nationalities[1], coordinates: const Offset(2, 17), owner: 'neutral'),
    ];

    final allVillages = [playerVillage, ai1Village, ai2Village, ...neutralVillages];

    map = VirtualMap(
      size: Size(GameConstants.mapWidth.toDouble(), GameConstants.mapHeight.toDouble()),
      villages: allVillages,
    );

    // Update player village lists
    for (var i = 0; i < players.length; i++) {
      final playerID = players[i].id;
      players[i] = players[i].copyWith(
        villages: allVillages.where((v) => v.owner == playerID).map((v) => v.name).toList(),
      );
    }

    notifyListeners();
  }

  String _getCapitalName(Nationality nationality) {
    return switch (nationality.name) {
      'Turkish' => 'Istanbul',
      'Greek' => 'Athens',
      'Bulgarian' => 'Sofia',
      _ => 'Capital',
    };
  }

  void initializeGame() {
    gameStarted = true;
    currentTurn = 1;
    syncGlobalResources();
    _createStartingArmies();
    notifyListeners();
  }

  void resetGame() {
    gameStarted = false;
    currentTurn = 0;
    currentPlayer = 'player';
    playerNationality = null;
    ai1Nationality = null;
    ai2Nationality = null;
    armies.clear();
    turnEvents.clear();
    globalResources.clear();
    discoveredVillageIDs.clear();

    map = VirtualMap(
      size: Size(GameConstants.mapWidth.toDouble(), GameConstants.mapHeight.toDouble()),
      villages: [],
    );
    players = Player.createPlayers();
    notifyListeners();
  }

  void _createStartingArmies() {
    for (final village in map.villages) {
      final startingUnits = <Unit>[];
      for (var i = 0; i < 3; i++) {
        startingUnits.add(Unit.create(UnitType.militia, village.owner, village.coordinates));
      }
      createArmy(startingUnits, village.id, village.owner);
    }
  }

  // Resource Management
  void syncGlobalResources() {
    for (final player in players) {
      final villages = getPlayerVillages(player.id);
      final totalResources = <Resource, int>{};

      for (final village in villages) {
        for (final entry in village.resources.entries) {
          totalResources[entry.key] = (totalResources[entry.key] ?? 0) + entry.value;
        }
      }
      globalResources[player.id] = totalResources;
    }
  }

  Map<Resource, int> getGlobalResources(String playerId) {
    return globalResources[playerId] ?? {};
  }

  void modifyGlobalResource(String playerId, Resource resource, int amount) {
    globalResources[playerId] ??= {};
    globalResources[playerId]![resource] = max(0, (globalResources[playerId]![resource] ?? 0) + amount);
  }

  bool canAfford(String playerId, Map<Resource, int> cost) {
    final resources = getGlobalResources(playerId);
    for (final entry in cost.entries) {
      if ((resources[entry.key] ?? 0) < entry.value) return false;
    }
    return true;
  }

  bool spendResources(String playerId, Map<Resource, int> cost) {
    if (!canAfford(playerId, cost)) return false;
    for (final entry in cost.entries) {
      modifyGlobalResource(playerId, entry.key, -entry.value);
    }
    return true;
  }

  // Village Management
  List<Village> getPlayerVillages(String playerId) {
    return map.villages.where((v) => v.owner == playerId).toList();
  }

  Village? getVillage(String name) {
    return map.villages.cast<Village?>().firstWhere(
          (v) => v!.name == name,
          orElse: () => null,
        );
  }

  void updateVillage(Village village) {
    final index = map.villages.indexWhere((v) => v.id == village.id);
    if (index != -1) {
      map.villages[index] = village;
      notifyListeners();
    }
  }

  // Army Management
  List<Army> getArmiesAt(String villageId) {
    return armies.where((a) => a.stationedAt == villageId).toList();
  }

  List<Army> getArmiesFor(String playerId) {
    return armies.where((a) => a.owner == playerId).toList();
  }

  List<Army> getMarchingArmiesFor(String playerId) {
    return armies.where((a) => a.owner == playerId && a.isMarching).toList();
  }

  List<Army> getStationedArmiesFor(String playerId) {
    return armies.where((a) => a.owner == playerId && !a.isMarching).toList();
  }

  Army createArmy(List<Unit> units, String villageId, String owner) {
    final army = Army(
      name: Army.generateName(units, owner),
      units: units,
      owner: owner,
      stationedAt: villageId,
    );
    armies.add(army);
    return army;
  }

  void updateArmy(Army army) {
    final index = armies.indexWhere((a) => a.id == army.id);
    if (index != -1) {
      armies[index] = army;
      notifyListeners();
    }
  }

  void removeArmy(String armyId) {
    armies.removeWhere((a) => a.id == armyId);
  }

  void mergeArmiesAt(String villageId, String owner) {
    final armiesHere = armies.where((a) => a.stationedAt == villageId && a.owner == owner).toList();
    if (armiesHere.length <= 1) return;

    final allUnits = <Unit>[];
    for (final army in armiesHere) {
      allUnits.addAll(army.units);
      removeArmy(army.id);
    }
    createArmy(allUnits, villageId, owner);
  }

  bool sendArmy(String armyId, String destinationVillageId) {
    final armyIndex = armies.indexWhere((a) => a.id == armyId);
    if (armyIndex == -1) return false;

    final destination = map.villages.cast<Village?>().firstWhere(
          (v) => v!.id == destinationVillageId,
          orElse: () => null,
        );
    if (destination == null) return false;

    final origin = armies[armyIndex].stationedAt;
    if (origin == null) return false;

    final originVillage = map.villages.cast<Village?>().firstWhere(
          (v) => v!.id == origin,
          orElse: () => null,
        );
    if (originVillage == null) return false;

    final turns = Army.calculateTravelTime(originVillage.coordinates, destination.coordinates);

    armies[armyIndex].marchTo(destinationVillageId, turns, origin);

    addTurnEvent(ArmySentEvent(
      armyName: armies[armyIndex].name,
      destination: destination.name,
      turns: turns,
    ));

    notifyListeners();
    return true;
  }

  // Turn Events
  void addTurnEvent(TurnEvent event) {
    turnEvents.add(event);
  }

  void clearTurnEvents() {
    turnEvents.clear();
  }

  // Fog of War
  bool isVillageVisible(Village village, String playerId) {
    if (village.owner == playerId) return true;
    if (discoveredVillageIDs.contains(village.id)) return true;

    final playerVillages = getPlayerVillages(playerId);
    for (final pv in playerVillages) {
      final dist = _distance(pv.coordinates, village.coordinates);
      if (dist <= visionRange) {
        discoveredVillageIDs.add(village.id);
        return true;
      }
    }

    final playerArmies = getArmiesFor(playerId);
    for (final army in playerArmies) {
      if (army.stationedAt != null) {
        final stationedVillage = map.villages.cast<Village?>().firstWhere(
              (v) => v!.id == army.stationedAt,
              orElse: () => null,
            );
        if (stationedVillage != null) {
          final dist = _distance(stationedVillage.coordinates, village.coordinates);
          if (dist <= visionRange) {
            discoveredVillageIDs.add(village.id);
            return true;
          }
        }
      }
    }
    return false;
  }

  bool isArmyVisible(Army army, String playerId) {
    if (army.owner == playerId) return true;

    final locationId = army.stationedAt ?? army.destination;
    if (locationId == null) return false;

    final locationVillage = map.villages.cast<Village?>().firstWhere(
          (v) => v!.id == locationId,
          orElse: () => null,
        );
    if (locationVillage == null) return false;

    final playerVillages = getPlayerVillages(playerId);
    for (final pv in playerVillages) {
      if (_distance(pv.coordinates, locationVillage.coordinates) <= visionRange) {
        return true;
      }
    }

    final playerArmies = getArmiesFor(playerId);
    for (final pa in playerArmies) {
      if (pa.stationedAt != null) {
        final paVillage = map.villages.cast<Village?>().firstWhere(
              (v) => v!.id == pa.stationedAt,
              orElse: () => null,
            );
        if (paVillage != null && _distance(paVillage.coordinates, locationVillage.coordinates) <= visionRange) {
          return true;
        }
      }
    }
    return false;
  }

  double _distance(Offset from, Offset to) {
    return sqrt(pow(to.dx - from.dx, 2) + pow(to.dy - from.dy, 2));
  }

  List<Village> getVisibleVillages(String playerId) {
    return map.villages.where((v) => isVillageVisible(v, playerId)).toList();
  }

  List<Army> getVisibleArmies(String playerId) {
    return armies.where((a) => isArmyVisible(a, playerId)).toList();
  }

  // Victory/Defeat
  Player? getWinner() {
    final activePlayers = players.where((p) => !p.isEliminated).toList();
    if (activePlayers.length == 1) return activePlayers.first;
    return null;
  }

  bool get isPlayerDefeated {
    final player = players.firstWhere((p) => p.isHuman);
    return player.isEliminated;
  }
}
