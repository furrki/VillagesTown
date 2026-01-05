import 'dart:math';
import 'package:flutter/foundation.dart';
import '../data/map/game_map.dart';
import '../data/map/virtual_map.dart';
import '../data/models/army.dart';
import '../data/models/geo_coordinate.dart';
import '../data/models/nationality.dart';
import '../data/models/player.dart';
import '../data/models/resource.dart';
import '../data/models/turn_event.dart';
import '../data/models/unit.dart';
import '../data/models/unit_type.dart';
import '../data/models/village.dart';
import '../data/models/building.dart';
import '../data/models/combat_log.dart';
import 'turn_engine.dart';

class GameManager extends ChangeNotifier {
  static final GameManager _instance = GameManager._internal();
  static GameManager get shared => _instance;
  factory GameManager() => _instance;
  GameManager._internal() {
    map = VirtualMap(villages: []);
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
  List<BattleRecord> pendingBattles = [];
  Set<String> discoveredVillageIDs = {};
  double visionRangeKm = 400.0; // Vision range in kilometers

  bool tutorialEnabled = true;
  int tutorialStep = 0;
  Set<String> completedTutorialActions = {};

  void completeTutorialAction(String actionName) {
    if (!completedTutorialActions.contains(actionName)) {
      completedTutorialActions.add(actionName);
      notifyListeners();
    }
  }

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

    // Historical cities with real coordinates
    // Capitals - stronger garrisons
    final playerVillage = Village(
      name: _getCapitalName(nationality),
      nationality: nationality,
      coordinates: _getCapitalCoordinates(nationality),
      owner: 'player',
      garrisonStrength: 15,
      garrisonMaxStrength: 25,
    );

    final ai1Village = Village(
      name: _getCapitalName(ai1Nationality!),
      nationality: ai1Nationality!,
      coordinates: _getCapitalCoordinates(ai1Nationality!),
      owner: 'ai1',
      garrisonStrength: 15,
      garrisonMaxStrength: 25,
    );

    final ai2Village = Village(
      name: _getCapitalName(ai2Nationality!),
      nationality: ai2Nationality!,
      coordinates: _getCapitalCoordinates(ai2Nationality!),
      owner: 'ai2',
      garrisonStrength: 15,
      garrisonMaxStrength: 25,
    );

    // Non-capital cities (12 neutral cities)
    final neutralVillages = [
      // Byzantine cities
      Village(name: 'Zonguldak', nationality: Nationality.byzantines, coordinates: const GeoCoordinate(41.4564, 31.7987), owner: 'neutral'),
      Village(name: 'Thessaloniki', nationality: Nationality.byzantines, coordinates: const GeoCoordinate(40.6401, 22.9444), owner: 'neutral'),
      Village(name: 'Trebizond', nationality: Nationality.byzantines, coordinates: const GeoCoordinate(41.0027, 39.7168), owner: 'neutral'),
      Village(name: 'Smyrna', nationality: Nationality.byzantines, coordinates: const GeoCoordinate(38.4237, 27.1428), owner: 'neutral'),
      // Ottoman cities
      Village(name: 'Konya', nationality: Nationality.ottomans, coordinates: const GeoCoordinate(37.8714, 32.4846), owner: 'neutral'),
      Village(name: 'Edirne', nationality: Nationality.ottomans, coordinates: const GeoCoordinate(41.6771, 26.5557), owner: 'neutral'),
      // Crusader cities
      Village(name: 'Antioch', nationality: Nationality.crusaders, coordinates: const GeoCoordinate(36.2028, 36.1600), owner: 'neutral'),
      Village(name: 'Jerusalem', nationality: Nationality.crusaders, coordinates: const GeoCoordinate(31.7683, 35.2137), owner: 'neutral'),
      // Neutral contested cities
      Village(name: 'Athens', nationality: Nationality.byzantines, coordinates: const GeoCoordinate(37.9838, 23.7275), owner: 'neutral'),
      Village(name: 'Damascus', nationality: Nationality.ottomans, coordinates: const GeoCoordinate(33.5138, 36.2765), owner: 'neutral'),
      Village(name: 'Aleppo', nationality: Nationality.ottomans, coordinates: const GeoCoordinate(36.2021, 37.1343), owner: 'neutral'),
      Village(name: 'Sofia', nationality: Nationality.byzantines, coordinates: const GeoCoordinate(42.6977, 23.3219), owner: 'neutral'),
    ];

    final allVillages = [playerVillage, ai1Village, ai2Village, ...neutralVillages];

    map = VirtualMap(villages: allVillages);

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
    return switch (nationality.id) {
      'ottoman' => 'Bursa',
      'byzantine' => 'Constantinople',
      'crusader' => 'Acre',
      _ => 'Capital',
    };
  }

  GeoCoordinate _getCapitalCoordinates(Nationality nationality) {
    return switch (nationality.id) {
      'ottoman' => const GeoCoordinate(40.1826, 29.0665), // Bursa
      'byzantine' => const GeoCoordinate(41.0082, 28.9784), // Constantinople
      'crusader' => const GeoCoordinate(32.9226, 35.0690), // Acre
      _ => const GeoCoordinate(40.0, 30.0),
    };
  }

  List<Building> _generateBuildings({required bool isCapital}) {
    if (isCapital) {
      return [
        Building.farm.copyWith(level: 5),
        Building.lumberMill.copyWith(level: 5),
        Building.ironMine.copyWith(level: 3),
        Building.market.copyWith(level: 3),
        Building.barracks.copyWith(level: 3),
        Building.fortress.copyWith(level: 1),
      ];
    } else {
      // Neutral - significantly weaker and random
      final buildings = <Building>[];
      final random = Random();
      
      // Always some food
      buildings.add(Building.farm.copyWith(level: random.nextInt(2) + 1)); // Lv 1-2
      
      // Random resource
      if (random.nextBool()) buildings.add(Building.lumberMill.copyWith(level: 1));
      if (random.nextBool()) buildings.add(Building.ironMine.copyWith(level: 1));
      
      // Random defense
      if (random.nextBool()) buildings.add(Building.barracks.copyWith(level: 1));
      
      return buildings;
    }
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

    map = VirtualMap(villages: []);
    players = Player.createPlayers();
    notifyListeners();
  }

  void _createStartingArmies() {
    for (final village in map.villages) {
      final startingUnits = <Unit>[];
      for (var i = 0; i < 15; i++) {
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

    final army = armies[armyIndex];

    // If attacking enemy village, trigger combat immediately
    if (destination.owner != army.owner && destination.owner != 'neutral') {
      // Move army to destination for combat
      army.station(destinationVillageId);
      army.origin = origin; // Preserve origin for retreat

      // Trigger combat via TurnEngine
      turnEngine.triggerImmediateCombat(army, destination, origin);

      notifyListeners();
      return true;
    }

    // Normal march for friendly/neutral destinations
    final turns = Army.calculateTravelTime(originVillage.coordinates, destination.coordinates);
    army.marchTo(destinationVillageId, turns, origin);

    addTurnEvent(ArmySentEvent(
      armyName: army.name,
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
      final distKm = GeoCoordinate.distanceKm(pv.coordinates, village.coordinates);
      if (distKm <= visionRangeKm) {
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
          final distKm = GeoCoordinate.distanceKm(stationedVillage.coordinates, village.coordinates);
          if (distKm <= visionRangeKm) {
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
      if (GeoCoordinate.distanceKm(pv.coordinates, locationVillage.coordinates) <= visionRangeKm) {
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
        if (paVillage != null && GeoCoordinate.distanceKm(paVillage.coordinates, locationVillage.coordinates) <= visionRangeKm) {
          return true;
        }
      }
    }
    return false;
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

  void finalizeBattle(BattleRecord record, int roundsPlayed, bool retreated) {
    // 1. Get Participants
    final attacker = armies.cast<Army?>().firstWhere((a) => a!.id == record.attackerId, orElse: () => null);
    
    // Defender logic is tricky because it might be a Village (Siege) or Army (Field).
    // We used 'defenderId' which is either Army.id or Village.id.
    Army? defenderArmy = armies.cast<Army?>().firstWhere((a) => a!.id == record.defenderId, orElse: () => null);
    Village? defenderVillage;
    if (defenderArmy == null) {
      defenderVillage = map.villages.cast<Village?>().firstWhere((v) => v!.id == record.defenderId, orElse: () => null);
    }
    
    if (attacker == null) return; // Should not happen

    // 2. Calculate Actual Losses based on rounds played
    int attLosses = 0;
    int defLosses = 0;
    
    for (var i = 0; i < roundsPlayed; i++) {
      if (i < record.rounds.length) {
        attLosses += record.rounds[i].attackerLosses;
        defLosses += record.rounds[i].defenderLosses;
      }
    }
    
    // 3. Apply Losses
    _applyCasualtiesToArmy(attacker, attLosses);
    
    if (defenderArmy != null) {
      _applyCasualtiesToArmy(defenderArmy, defLosses);
      if (defenderArmy.units.isEmpty) {
        removeArmy(defenderArmy.id);
      } else {
        updateArmy(defenderArmy);
      }
    } else if (defenderVillage != null) {
       // Siege defense involves potentially multiple armies + garrison.
       // For MVP simplicity, we kill garrison units from the 'defenderId' context if we could (but we don't have the list easily without reconstructing).
       // Actually, CombatEngine passed us a list of defenders. We need to apply damage to the entities that owned those units.
       // In the simple siege model, we just damage the garrison strength of the village directly proportional to losses?
       // OR we assume the TurnEngine passed us a transient list of units composed of garrison.
       
       // Simplified Siege Result Application:
       // If Attacker Won (roundsPlayed == record.rounds.length && record.attackerWon), we conquer.
       // If Retreat, we don't.
       
       // Determine if defenders (garrison) were wiped out.
       // We don't track persistent unit objects for garrison easily here.
       // So we rely on the simulation result for conquest state.
       
       // If we played ALL rounds, we trust the record's boolean outcome for potential conquest.
       // But we must account for retreat.
    }
    
    // 4. Handle Retreat
    if (retreated) {
      // 10% attrition penalty for retreating? Optional.
      // Move attacker back.
      if (record.originVillageId != null) {
        attacker.station(record.originVillageId!);
        updateArmy(attacker);
      }
      
      addTurnEvent(BattleLostEvent(
        location: record.locationName, 
        casualties: attLosses
      ));
      return; 
    }
    
    // 5. Handle Victory/Defeat (Non-Retreat)
    // Update Attacker
    if (attacker.units.isEmpty) {
      removeArmy(attacker.id);
      addTurnEvent(BattleLostEvent(location: record.locationName, casualties: attLosses));
    } else {
      updateArmy(attacker);
      if (defenderArmy == null && defenderVillage == null) {
         // Should not happen
      } else if (defenderArmy != null) {
        // Field Battle Victory if defender dead
        if (defenderArmy.units.isEmpty) {
           addTurnEvent(BattleWonEvent(location: record.locationName, casualties: attLosses));
        }
      } else {
        // Siege Victory?
        bool conquest = roundsPlayed == record.rounds.length && record.attackerWon;
        if (conquest && defenderVillage != null) {
             _conquerVillage(attacker, defenderVillage);
        } else {
             // Garrison damage
             if (defenderVillage != null) {
                defenderVillage.damageGarrison(max(1, defLosses ~/ 2));
                defenderVillage.underSiege = false;
                updateVillage(defenderVillage);
             }
             // Attacker bounces or stays for siege? 
             // Logic: failed siege usually stays outside? Or bounces?
             // "Risk" bounces if you don't take it.
             if (record.originVillageId != null) {
                attacker.station(record.originVillageId!);
             }
             addTurnEvent(BattleLostEvent(location: record.locationName, casualties: attLosses));
        }
      }
    }
    
    // Mark record as processed
    record.isPending = false;
    pendingBattles.remove(record);
    notifyListeners();
  }
  
  void _applyCasualtiesToArmy(Army army, int count) {
    int killed = 0;
    for (var i = 0; i < army.units.length && killed < count; i++) {
       if (army.units[i].isAlive) {
         army.units[i].takeDamage(9999);
         killed++;
       }
    }
    army.removeDeadUnits();
  }

  void _conquerVillage(Army attacker, Village village) {
      final oldOwner = village.owner;
      village.owner = attacker.owner;
      village.population = (village.population * 0.8).toInt();
      village.happiness = max(30, village.happiness - 20);
      village.garrisonStrength = 5;
      village.underSiege = false;
      updateVillage(village);

      // Station attacking army
      attacker.station(village.id);
      updateArmy(attacker);

      if (attacker.owner == 'player') {
        addTurnEvent(VillageConqueredEvent(villageName: village.name));
      } else if (oldOwner == 'player') {
        addTurnEvent(VillageLostEvent(villageName: village.name));
      }
  }

  /// Auto-finalize battles that don't involve the player
  void finalizeAIBattles() {
    final toFinalize = <BattleRecord>[];

    for (final battle in pendingBattles) {
      bool playerInvolved = false;

      // Check if player's army is the attacker
      final attackerArmy = armies.cast<Army?>().firstWhere(
        (a) => a!.id == battle.attackerId,
        orElse: () => null,
      );
      if (attackerArmy?.owner == 'player') playerInvolved = true;

      // Check if player's village is being attacked
      if (!playerInvolved) {
        final defenderVillage = map.villages.cast<Village?>().firstWhere(
          (v) => v!.id == battle.defenderId,
          orElse: () => null,
        );
        if (defenderVillage?.owner == 'player') playerInvolved = true;
      }

      if (!playerInvolved) {
        toFinalize.add(battle);
      }
    }

    // Finalize all AI battles (play all rounds, no retreat)
    for (final battle in toFinalize) {
      finalizeBattle(battle, battle.rounds.length, false);
    }
  }
}
