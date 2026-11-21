import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
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
import '../data/models/combat_log.dart';
import '../data/models/difficulty.dart';
import '../data/models/achievement.dart';
import '../data/models/game_event.dart';
import '../data/models/game_modifier.dart';
import '../data/models/victory_condition.dart';
import '../data/models/village_trait.dart';
import '../data/models/character_origin.dart';
import '../data/models/mission.dart';
import '../data/models/player_character.dart';
import '../data/models/trade_good.dart';
import '../data/models/encounter.dart';
import '../data/models/battle_plan.dart';
import 'combat_engine.dart';
import 'recruitment_engine.dart';
import 'encounter_engine.dart';
import 'save_engine.dart';
import 'event_engine.dart';
import 'game_loop.dart';
import 'turn_engine.dart';

part 'game_manager_rts.dart';

class GameManager extends ChangeNotifier {
  static final GameManager _instance = GameManager._internal();
  static GameManager get shared => _instance;
  factory GameManager() => _instance;
  GameManager._internal() {
    map = VirtualMap(villages: []);
  }

  static const int maxNeighborsPerCity = 4; // K-nearest neighbors
  static const double maxConnectionDistanceKm = 500.0; // Hard cap to prevent sea crossings

  Map<String, Set<String>> cityConnections = {};

  late GameMap map;
  List<Player> players = Player.createPlayers();
  int currentTurn = 0;
  String currentPlayer = 'player';
  bool gameStarted = false;
  Nationality? playerNationality;

  late final TurnEngine turnEngine = TurnEngine();

  Map<String, Map<Resource, int>> globalResources = {};
  List<Army> armies = [];
  List<TurnEvent> turnEvents = [];
  List<BattleRecord> pendingBattles = [];
  Set<String> discoveredVillageIDs = {};

  Map<String, Map<TradeGood, double>> marketPressure = {};
  double visionRangeKm = 400.0; // Vision range in kilometers

  Map<String, DiscoveredVillageInfo> discoveredVillageCache = {};

  VictoryType? selectedVictoryType;
  Map<String, int> battlesWon = {};
  VictoryType? achievedVictoryType;
  bool gameEndRecorded = false;
  Future<List<Achievement>>? gameEndRecording;
  String campaignId = const Uuid().v4();
  final campaignSaveFailed = ValueNotifier(false);
  List<Achievement>? pendingEndAchievements;

  List<GameEvent> activeEvents = [];
  List<GameEvent> eventHistory = [];

  Difficulty? difficulty;

  Set<GameModifier> activeModifiers = {};

  int battlesLost = 0;
  int peakGold = 0;
  int peakVillageCount = 0;
  bool lostCapital = false;
  bool hadCavalryOnlyBattleWin = false;
  bool conqueredDuringWinter = false;
  List<int> conquestTurns = []; // turns when villages were conquered
  Map<String, int> previousTurnVillageCounts = {};
  String? capitalVillageId;

  PlayerCharacter? playerCharacter;
  final GameLoop gameLoop = GameLoop();
  Encounter? currentEncounter;
  bool isGameOver = false;
  final List<String> pendingNotifications = [];

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
    campaignId = const Uuid().v4();
    playerNationality = nationality;

    players[0] = players[0].copyWith(nationality: nationality);

    for (var i = 1; i < players.length; i++) {
      if (players[i].nationality.id == nationality.id) {
        players[i] = players[i].copyWith(isEliminated: true);
        break;
      }
    }

    final allVillages = _buildAllCities(nationality);

    map = VirtualMap(villages: allVillages);

    _loadTerritories(allVillages);

    _buildCityConnections();

    for (var i = 0; i < players.length; i++) {
      final playerID = players[i].id;
      players[i] = players[i].copyWith(
        villages: allVillages.where((v) => v.owner == playerID).map((v) => v.name).toList(),
      );
    }

    notifyListeners();
  }

  void _loadTerritories(List<Village> villages) {
    rootBundle.loadString('assets/territories.json').then((content) {
      try {
        final data = json.decode(content) as Map<String, dynamic>;
        for (final village in villages) {
          if (data.containsKey(village.name)) {
            final coords = data[village.name] as List;
            village.customTerritory = coords
                .map((c) => LatLng(c[1] as double, c[0] as double))
                .toList();
          }
        }
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading territories: $e');
      }
    }).catchError((e) {
      debugPrint('No territories.json asset found: $e');
    });
  }

  List<Village> _buildAllCities(Nationality playerNationality) {
    final villages = <Village>[];

    String getOwner(Nationality nat) {
      if (nat.id == playerNationality.id) return 'player';
      for (final p in players) {
        if (!p.isHuman && p.nationality.id == nat.id) return p.id;
      }
      return 'neutral';
    }

    villages.add(Village(
      name: 'Constantinople', nationality: Nationality.byzantines,
      coordinates: const GeoCoordinate(41.0082, 28.9784),
      owner: getOwner(Nationality.byzantines),
      garrisonStrength: 20, garrisonMaxStrength: 30,
    ));
    villages.add(Village(
      name: 'Bursa', nationality: Nationality.ottomans,
      coordinates: const GeoCoordinate(40.1826, 29.0665),
      owner: getOwner(Nationality.ottomans),
      garrisonStrength: 20, garrisonMaxStrength: 30,
    ));
    villages.add(Village(
      name: 'Acre', nationality: Nationality.crusaders,
      coordinates: const GeoCoordinate(32.9226, 35.0690),
      owner: getOwner(Nationality.crusaders),
      garrisonStrength: 20, garrisonMaxStrength: 30,
    ));

    villages.add(Village(
      name: 'Tarnovo', nationality: Nationality.bulgaria,
      coordinates: const GeoCoordinate(43.0757, 25.6172),
      owner: getOwner(Nationality.bulgaria),
      garrisonStrength: 12, garrisonMaxStrength: 20,
    ));
    villages.add(Village(
      name: 'Belgrade', nationality: Nationality.serbia,
      coordinates: const GeoCoordinate(44.7866, 20.4489),
      owner: getOwner(Nationality.serbia),
      garrisonStrength: 12, garrisonMaxStrength: 20,
    ));
    villages.add(Village(
      name: 'Ani', nationality: Nationality.armenia,
      coordinates: const GeoCoordinate(40.5053, 43.5728),
      owner: getOwner(Nationality.armenia),
      garrisonStrength: 12, garrisonMaxStrength: 20,
    ));
    villages.add(Village(
      name: 'Cairo', nationality: Nationality.mamluks,
      coordinates: const GeoCoordinate(30.0444, 31.2357),
      owner: getOwner(Nationality.mamluks),
      garrisonStrength: 15, garrisonMaxStrength: 25,
    ));

    villages.add(Village(
      name: 'Thessaloniki', nationality: Nationality.byzantines,
      coordinates: const GeoCoordinate(40.6401, 22.9444),
      owner: getOwner(Nationality.byzantines),
      garrisonStrength: 10, garrisonMaxStrength: 18,
    ));
    villages.add(Village(
      name: 'Nicaea', nationality: Nationality.byzantines,
      coordinates: const GeoCoordinate(40.4292, 29.7211),
      owner: getOwner(Nationality.byzantines),
      garrisonStrength: 10, garrisonMaxStrength: 18,
    ));

    villages.add(Village(
      name: 'Konya', nationality: Nationality.ottomans,
      coordinates: const GeoCoordinate(37.8714, 32.4846),
      owner: getOwner(Nationality.ottomans),
      garrisonStrength: 10, garrisonMaxStrength: 18,
    ));
    villages.add(Village(
      name: 'Ankara', nationality: Nationality.ottomans,
      coordinates: const GeoCoordinate(39.9334, 32.8597),
      owner: getOwner(Nationality.ottomans),
      garrisonStrength: 10, garrisonMaxStrength: 18,
    ));

    villages.add(Village(
      name: 'Jerusalem', nationality: Nationality.crusaders,
      coordinates: const GeoCoordinate(31.7683, 35.2137),
      owner: getOwner(Nationality.crusaders),
      garrisonStrength: 12, garrisonMaxStrength: 20,
    ));
    villages.add(Village(
      name: 'Antioch', nationality: Nationality.crusaders,
      coordinates: const GeoCoordinate(36.2028, 36.1600),
      owner: getOwner(Nationality.crusaders),
      garrisonStrength: 10, garrisonMaxStrength: 18,
    ));

    villages.add(Village(
      name: 'Sofia', nationality: Nationality.bulgaria,
      coordinates: const GeoCoordinate(42.6977, 23.3219),
      owner: getOwner(Nationality.bulgaria),
      garrisonStrength: 8, garrisonMaxStrength: 15,
    ));

    villages.add(Village(
      name: 'Nis', nationality: Nationality.serbia,
      coordinates: const GeoCoordinate(43.3209, 21.8954),
      owner: getOwner(Nationality.serbia),
      garrisonStrength: 8, garrisonMaxStrength: 15,
    ));

    villages.add(Village(
      name: 'Van', nationality: Nationality.armenia,
      coordinates: const GeoCoordinate(38.4891, 43.4089),
      owner: getOwner(Nationality.armenia),
      garrisonStrength: 8, garrisonMaxStrength: 15,
    ));

    villages.add(Village(
      name: 'Alexandria', nationality: Nationality.mamluks,
      coordinates: const GeoCoordinate(31.2001, 29.9187),
      owner: getOwner(Nationality.mamluks),
      garrisonStrength: 10, garrisonMaxStrength: 18,
    ));
    villages.add(Village(
      name: 'Damascus', nationality: Nationality.mamluks,
      coordinates: const GeoCoordinate(33.5138, 36.2765),
      owner: getOwner(Nationality.mamluks),
      garrisonStrength: 10, garrisonMaxStrength: 18,
    ));

    villages.add(Village(name: 'Smyrna', nationality: Nationality.byzantines, coordinates: const GeoCoordinate(38.4237, 27.1428), owner: 'neutral'));
    villages.add(Village(name: 'Trebizond', nationality: Nationality.byzantines, coordinates: const GeoCoordinate(41.0027, 39.7168), owner: 'neutral'));
    villages.add(Village(name: 'Sinope', nationality: Nationality.byzantines, coordinates: const GeoCoordinate(42.0231, 35.1531), owner: 'neutral'));
    villages.add(Village(name: 'Edirne', nationality: Nationality.ottomans, coordinates: const GeoCoordinate(41.6771, 26.5557), owner: 'neutral'));
    villages.add(Village(name: 'Erzurum', nationality: Nationality.armenia, coordinates: const GeoCoordinate(39.9043, 41.2679), owner: 'neutral'));

    villages.add(Village(name: 'Athens', nationality: Nationality.byzantines, coordinates: const GeoCoordinate(37.9838, 23.7275), owner: 'neutral'));
    villages.add(Village(name: 'Skopje', nationality: Nationality.serbia, coordinates: const GeoCoordinate(41.9981, 21.4254), owner: 'neutral'));
    villages.add(Village(name: 'Plovdiv', nationality: Nationality.bulgaria, coordinates: const GeoCoordinate(42.1354, 24.7453), owner: 'neutral'));

    villages.add(Village(name: 'Aleppo', nationality: Nationality.mamluks, coordinates: const GeoCoordinate(36.2021, 37.1343), owner: 'neutral'));
    villages.add(Village(name: 'Tripoli', nationality: Nationality.crusaders, coordinates: const GeoCoordinate(34.4367, 35.8497), owner: 'neutral'));
    villages.add(Village(name: 'Gaza', nationality: Nationality.mamluks, coordinates: const GeoCoordinate(31.5, 34.4667), owner: 'neutral'));

    villages.add(Village(name: 'Rhodes', nationality: Nationality.crusaders, coordinates: const GeoCoordinate(36.4349, 28.2176), owner: 'neutral'));
    villages.add(Village(name: 'Crete', nationality: Nationality.byzantines, coordinates: const GeoCoordinate(35.2401, 24.8093), owner: 'neutral'));
    villages.add(Village(name: 'Cyprus', nationality: Nationality.crusaders, coordinates: const GeoCoordinate(35.1264, 33.4299), owner: 'neutral'));

    villages.add(Village(name: 'Kars', nationality: Nationality.armenia, coordinates: const GeoCoordinate(40.6013, 43.0975), owner: 'neutral'));

    _assignVillageTraits(villages);

    return villages;
  }

  void _assignVillageTraits(List<Village> villages) {
    const traitMap = <String, VillageTrait>{
      'Cairo': VillageTrait.fertile,
      'Damascus': VillageTrait.fertile,
      'Alexandria': VillageTrait.fertile,
      'Thessaloniki': VillageTrait.fertile,
      'Gaza': VillageTrait.fertile,
      'Sofia': VillageTrait.forested,
      'Tarnovo': VillageTrait.forested,
      'Belgrade': VillageTrait.forested,
      'Nis': VillageTrait.forested,
      'Van': VillageTrait.mountainous,
      'Kars': VillageTrait.mountainous,
      'Ani': VillageTrait.mountainous,
      'Erzurum': VillageTrait.mountainous,
      'Konya': VillageTrait.mountainous,
      'Constantinople': VillageTrait.tradeCrossroads,
      'Antioch': VillageTrait.tradeCrossroads,
      'Aleppo': VillageTrait.tradeCrossroads,
      'Bursa': VillageTrait.tradeCrossroads,
      'Acre': VillageTrait.coastal,
      'Smyrna': VillageTrait.coastal,
      'Trebizond': VillageTrait.coastal,
      'Sinope': VillageTrait.coastal,
      'Tripoli': VillageTrait.coastal,
      'Rhodes': VillageTrait.coastal,
      'Crete': VillageTrait.coastal,
      'Cyprus': VillageTrait.coastal,
      'Jerusalem': VillageTrait.strategic,
      'Nicaea': VillageTrait.strategic,
      'Ankara': VillageTrait.strategic,
      'Edirne': VillageTrait.strategic,
    };

    for (final village in villages) {
      village.trait = traitMap[village.name] ?? VillageTrait.none;
    }
  }

  void _buildCityConnections() {
    cityConnections.clear();

    for (final village in map.villages) {
      final candidates = <(Village, double)>[];

      for (final other in map.villages) {
        if (other.id == village.id) continue;
        final dist = GeoCoordinate.distanceKm(village.coordinates, other.coordinates);
        if (dist <= maxConnectionDistanceKm) {
          candidates.add((other, dist));
        }
      }

      candidates.sort((a, b) => a.$2.compareTo(b.$2));
      final neighbors = candidates.take(maxNeighborsPerCity).map((c) => c.$1.id).toSet();
      cityConnections[village.id] = neighbors;
    }

    final symmetric = <String, Set<String>>{};
    for (final entry in cityConnections.entries) {
      symmetric[entry.key] ??= {};
      symmetric[entry.key]!.addAll(entry.value);
      for (final neighborId in entry.value) {
        symmetric[neighborId] ??= {};
        symmetric[neighborId]!.add(entry.key);
      }
    }
    cityConnections = symmetric;
  }


  void initializeGame({
    String characterName = '',
    CharacterOrigin? origin,
  }) {
    gameStarted = true;
    currentTurn = 1;
    syncGlobalResources();
    _createStartingArmies();

    final playerVillages = getPlayerVillages('player');
    if (playerVillages.isNotEmpty) {
      capitalVillageId = playerVillages.first.id;
    }

    final goldBonus = difficulty?.playerStartGoldBonus ?? 0;
    if (goldBonus != 0) {
      modifyGlobalResource('player', Resource.gold, goldBonus);
    }

    if (activeModifiers.contains(GameModifier.fogEternal)) {
      visionRangeKm = 200.0;
    }
    if (activeModifiers.contains(GameModifier.openBook)) {
      visionRangeKm = 99999.0;
      for (final v in map.villages) {
        discoveredVillageIDs.add(v.id);
      }
    }

    final startCity = getPlayerVillages('player').firstOrNull;
    final startGold = 150 + (origin?.bonusGold ?? 0);
    playerCharacter = PlayerCharacter(
      name: characterName,
      origin: origin,
      currentCityId: startCity?.id,
      gold: startGold,
      combatSkill: 1 + (origin?.bonusCombat ?? 0),
      leadershipSkill: 1 + (origin?.bonusLeadership ?? 0),
      tacticsSkill: 1 + (origin?.bonusTactics ?? 0),
      tradeSkill: 1 + (origin?.bonusTrade ?? 0),
      scoutingSkill: 1 + (origin?.bonusScouting ?? 0),
      packMules: (origin?.startsWithPackMule ?? false) ? 1 : 0,
    );

    absorbPurse();

    if (startCity != null) {
      final startingUnits = <Unit>[
        ...List.generate(
          3 + (origin?.bonusMilitia ?? 0),
          (_) => Unit.create(UnitType.militia, 'player', startCity.coordinates),
        ),
        Unit.create(UnitType.spearman, 'player', startCity.coordinates),
        ...List.generate(
          origin?.bonusSwordsmen ?? 0,
          (_) => Unit.create(UnitType.swordsman, 'player', startCity.coordinates),
        ),
      ];
      playerCharacter!.warbandId = createArmy(startingUnits, startCity.id, 'player').id;
    }

    if (origin != null && startCity != null) {
      _createInitialMission(origin, startCity.id);
    }

    gameLoop.onTick = _onGameTick;
    gameLoop.onArrival = _onPlayerArrival;

    notifyListeners();
  }

  Iterable<MissionObjective> unfinishedObjectivesFor(String playerId) sync* {
    final character = playerCharacter;
    if (playerId != 'player' || character == null) return;
    for (final mission in character.activeMissions) {
      if (mission.state == MissionState.active) {
        yield* mission.objectives.where((objective) => !objective.completed);
      }
    }
  }

  String? goalCityIdFor(String playerId) => unfinishedObjectivesFor(playerId)
      .where((objective) => objective.targetCityId != null &&
          (objective.type == ObjectiveType.travelTo ||
              objective.type == ObjectiveType.deliverGoods))
      .firstOrNull?.targetCityId;

  void _createInitialMission(CharacterOrigin origin, String startCityId) {
    final neighbors = getNeighbors(startCityId);
    if (neighbors.isEmpty) return;
    final nearest = neighbors.first;
    final nearestName = getVillageDisplayName(nearest);
    final mission = origin.createInitialMission(
      startCityId: startCityId,
      nearestCityId: nearest.id,
      nearestCityName: nearestName,
    );
    playerCharacter?.activeMissions.add(mission);
  }

  void resetGame() {
    gameStarted = false;
    _citySaveTimer?.cancel();
    _citySaveTimer = null;
    campaignSaveFailed.value = false;
    currentTurn = 0;
    currentPlayer = 'player';
    playerNationality = null;
    armies.clear();
    turnEvents.clear();
    globalResources.clear();
    discoveredVillageIDs.clear();
    discoveredVillageCache.clear();
    marketPressure.clear();
    lastBattleReport = null;
    pendingBattles.clear();
    cityConnections.clear();
    tutorialEnabled = true;
    tutorialStep = 0;
    completedTutorialActions.clear();
    selectedVictoryType = null;
    battlesWon.clear();
    achievedVictoryType = null;
    gameEndRecorded = false;
    gameEndRecording = null;
    pendingEndAchievements = null;
    activeEvents.clear();
    eventHistory.clear();
    difficulty = null;
    activeModifiers.clear();
    visionRangeKm = 400.0;
    battlesLost = 0;
    peakGold = 0;
    peakVillageCount = 0;
    lostCapital = false;
    hadCavalryOnlyBattleWin = false;
    conqueredDuringWinter = false;
    conquestTurns.clear();
    previousTurnVillageCounts.clear();
    capitalVillageId = null;
    gameLoop.dispose();
    playerCharacter = null;
    currentEncounter = null;
    isGameOver = false;

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

  void refreshUI() => notifyListeners();

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

  int get gold => (getGlobalResources('player')[Resource.gold] ?? 0) + (playerCharacter?.gold ?? 0);

  void awardGold(int n) {
    final pc = playerCharacter!;
    if (getPlayerVillages('player').isEmpty) {
      pc.gold += n;
    } else {
      absorbPurse();
      modifyGlobalResource('player', Resource.gold, n);
    }
    pc.totalGoldEarned += n;
  }

  bool spendGold(int n) {
    if (gold < n) return false;
    final pc = playerCharacter;
    final fromPurse = min(pc?.gold ?? 0, n);
    if (pc != null) pc.gold -= fromPurse;
    modifyGlobalResource('player', Resource.gold, -(n - fromPurse));
    return true;
  }

  void absorbPurse() {
    final pc = playerCharacter;
    if (pc == null || getPlayerVillages('player').isEmpty) return;
    modifyGlobalResource('player', Resource.gold, pc.gold);
    pc.gold = 0;
  }

  bool healWarband(int cost) {
    if (!spendGold(cost)) return false;
    for (final unit in playerWarband?.units ?? <Unit>[]) {
      unit.currentHP = unit.maxHP;
    }
    notifyListeners();
    return true;
  }

  void modifyGlobalResource(String playerId, Resource resource, int amount) {
    final villages = getPlayerVillages(playerId);
    if (villages.isEmpty || amount == 0) return;
    if (amount > 0) {
      final capital = playerId == 'player' ? getVillageById(capitalVillageId) : null;
      (capital != null && capital.owner == playerId ? capital : villages.first).addResource(resource, amount);
    } else {
      var owed = -amount;
      villages.sort((a, b) => (b.resources[resource] ?? 0).compareTo(a.resources[resource] ?? 0));
      for (final v in villages) {
        if (owed == 0) break;
        final take = min(owed, v.resources[resource] ?? 0);
        v.resources[resource] = (v.resources[resource] ?? 0) - take;
        owed -= take;
      }
    }
    final total = <Resource, int>{};
    for (final v in villages) {
      for (final e in v.resources.entries) {
        total[e.key] = (total[e.key] ?? 0) + e.value;
      }
    }
    globalResources[playerId] = total;
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

  Nationality? getNationality(String ownerId) {
    if (ownerId == 'neutral') return null;
    final player = getPlayerById(ownerId);
    return player?.nationality;
  }

  String getVillageDisplayName(Village village) {
    return village.displayName(getNationality(village.owner));
  }

  List<Village> getPlayerVillages(String playerId) {
    return map.villages.where((v) => v.owner == playerId).toList();
  }

  Village? getVillage(String name) {
    for (final v in map.villages) {
      if (v.name == name) return v;
    }
    return null;
  }

  Player? getPlayerById(String? ownerId) {
    if (ownerId == null) return null;
    for (final p in players) {
      if (p.id == ownerId) return p;
    }
    return null;
  }

  Village? getVillageById(String? id) {
    if (id == null) return null;
    for (final v in map.villages) {
      if (v.id == id) return v;
    }
    return null;
  }

  Army? getArmyById(String? id) {
    if (id == null) return null;
    for (final a in armies) {
      if (a.id == id) return a;
    }
    return null;
  }

  void updateVillage(Village village) {
    final index = map.villages.indexWhere((v) => v.id == village.id);
    if (index != -1) {
      map.villages[index] = village;
      notifyListeners();
    }
  }

  List<Army> getArmiesAt(String villageId) {
    return armies.where((a) => a.stationedAt == villageId).toList();
  }

  int getTotalDefenders(Village village) {
    final stationedArmies = getArmiesAt(village.id).where((a) => a.owner == village.owner);
    int armyUnits = 0;
    for (final army in stationedArmies) {
      armyUnits += army.unitCount;
    }
    return village.garrisonStrength + armyUnits;
  }

  List<Army> getArmiesFor(String playerId) {
    return armies.where((a) => a.owner == playerId).toList();
  }

  List<Army> getMarchingArmiesFor(String playerId) {
    return armies.where((a) => a.owner == playerId && a.isMarching).toList();
  }

  List<Army> getStationedArmiesFor(String playerId) {
    return armies.where((a) => a.owner == playerId && a.state == ArmyState.stationed).toList();
  }

  List<Army> getBesiegingArmiesAt(String villageId) {
    return armies.where((a) => a.stationedAt == villageId && a.state == ArmyState.besieging).toList();
  }

  List<Village> getSiegedVillagesFor(String playerId) {
    return map.villages.where((v) {
      final besiegers = getBesiegingArmiesAt(v.id);
      return besiegers.any((a) => a.owner == playerId);
    }).toList();
  }

  List<Village> getVillagesUnderSiegeFor(String playerId) {
    return map.villages.where((v) {
      return v.owner == playerId && getBesiegingArmiesAt(v.id).isNotEmpty;
    }).toList();
  }

  Army createArmy(List<Unit> units, String villageId, String owner) {
    final village = getVillageById(villageId);
    final ownerPlayer = getPlayerById(owner);
    final army = Army(
      name: Army.generateName(
        village?.name ?? 'Unknown',
        ownerPlayer?.nationality.id ?? 'crusader',
      ),
      units: units,
      owner: owner,
      stationedAt: villageId,
    );
    armies.add(army);
    notifyListeners();
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
    final armiesHere = armies
        .where((a) => a.stationedAt == villageId && a.owner == owner && a.id != playerCharacter?.warbandId)
        .toList();
    if (armiesHere.length <= 1) return;

    armiesHere.sort((a, b) => b.units.length.compareTo(a.units.length));
    final primary = armiesHere.first;

    final unitsToAdd = <Unit>[];
    for (var i = 1; i < armiesHere.length; i++) {
      unitsToAdd.addAll(armiesHere[i].units);
      removeArmy(armiesHere[i].id);
    }

    primary.units.addAll(unitsToAdd);
    updateArmy(primary);
  }

  BattleRecord? sallyOut(String villageId) {
    final village = getVillageById(villageId);
    if (village == null) return null;

    final besiegers = getBesiegingArmiesAt(villageId);
    if (besiegers.isEmpty) return null;

    final defenderArmies = getArmiesAt(villageId)
        .where((a) => a.owner == village.owner && a.state == ArmyState.stationed)
        .toList();
    final defenderUnits = defenderArmies.expand((a) => a.units).toList();
    final garrisonUnits = List.generate(
      village.garrisonStrength,
      (_) => Unit.create(UnitType.militia, village.owner, village.coordinates),
    );
    final allDefenders = [...defenderUnits, ...garrisonUnits];

    if (allDefenders.isEmpty) return null;

    final attackerUnits = besiegers.expand((a) => a.units).toList();
    if (attackerUnits.isEmpty) return null;

    final combatEngine = CombatEngine();
    final result = combatEngine.resolveCombat(
      attackerName: besiegers.first.name,
      defenderName: getVillageDisplayName(village),
      attackerId: besiegers.first.id,
      defenderId: villageId,
      attackerOwnerId: besiegers.first.owner,
      defenderOwnerId: village.owner,
      originVillageId: besiegers.first.origin,
      attackers: attackerUnits,
      defenders: allDefenders,
      map: map,
      defendingVillage: village,
      garrisonCount: village.garrisonStrength,
      defenderFortressLevel: 0, // NO fortress bonus for sally out!
    );

    if (result.rounds.isNotEmpty) {
      village.underSiege = false; // Battle resolving the siege

      for (final army in besiegers) {
        army.state = ArmyState.stationed;
        army.siegeTurns = 0;
      }

      final playerInvolved = result.attackerOwnerId == 'player' ||
                             result.defenderOwnerId == 'player';
      if (playerInvolved) {
        pendingBattles.add(result);
      } else {
        finalizeBattle(result, result.rounds.length, false);
      }

      addTurnEvent(GeneralEvent(text: '${village.name} garrison sallied out!'));
      notifyListeners();
      return result;
    }
    return null;
  }

  bool interceptArmy(String interceptorId, String targetArmyId) {
    final interceptor = getArmyById(interceptorId);
    if (interceptor == null) return false;

    if (interceptor.state != ArmyState.stationed) return false;
    if (interceptor.stationedAt == null) return false;

    final target = getArmyById(targetArmyId);
    if (target == null) return false;

    if (!target.isMarching) return false;
    if (target.owner == interceptor.owner) return false;

    final targetDest = target.destination;
    if (targetDest == null) return false;
    if (!areNeighbors(interceptor.stationedAt!, targetDest)) return false;

    final destination = getVillageById(targetDest);
    if (destination == null) return false;

    final originVillage = getVillageById(interceptor.stationedAt);
    if (originVillage == null) return false;

    final turns = Army.calculateTravelTime(originVillage.coordinates, destination.coordinates);
    interceptor.marchTo(targetDest, min(turns, target.turnsUntilArrival), interceptor.stationedAt);
    updateArmy(interceptor);

    addTurnEvent(GeneralEvent(text: '${interceptor.name} moving to intercept ${target.name}'));
    notifyListeners();
    return true;
  }

  bool areNeighbors(String villageId1, String villageId2) {
    return cityConnections[villageId1]?.contains(villageId2) ?? false;
  }

  List<Village> getNeighbors(String villageId) {
    final neighborIds = cityConnections[villageId];
    if (neighborIds == null) return [];
    return map.villages.where((v) => neighborIds.contains(v.id)).toList();
  }

  bool sendArmy(String armyId, String destinationVillageId) {
    final armyIndex = armies.indexWhere((a) => a.id == armyId);
    if (armyIndex == -1) return false;

    final destination = getVillageById(destinationVillageId);
    if (destination == null) return false;

    final origin = armies[armyIndex].stationedAt;
    if (origin == null) return false;

    if (!areNeighbors(origin, destinationVillageId)) return false;

    final originVillage = getVillageById(origin);
    if (originVillage == null) return false;

    final army = armies[armyIndex];

    if (destination.owner != army.owner) {
      final defendingArmies = getArmiesAt(destination.id).where((a) => a.owner == destination.owner).toList();
      final hasDefenders = destination.garrisonStrength > 0 || defendingArmies.isNotEmpty;

      if (!hasDefenders) {
        _captureUndefendedVillage(army, destination, origin);
        notifyListeners();
        return true;
      }
    }

    var turns = Army.calculateTravelTime(originVillage.coordinates, destination.coordinates);
    turns += EventEngine.movementPenalty(this);
    army.marchTo(destinationVillageId, turns, origin);
    updateArmy(army);

    if (destination.owner != army.owner) {
      addTurnEvent(ArmySentEvent(
        armyName: army.name,
        destination: '${destination.name} (siege)',
        turns: turns,
      ));
    } else {
      addTurnEvent(ArmySentEvent(
        armyName: army.name,
        destination: destination.name,
        turns: turns,
      ));
    }

    notifyListeners();
    return true;
  }

  void _captureUndefendedVillage(Army army, Village village, String originId) {
    village.owner = army.owner;
    village.happiness = max(40, village.happiness - 10);
    village.garrisonStrength = 0; // Reset garrison on conquest
    village.garrisonRegenAccumulator = 0.0;
    updateVillage(village);

    army.station(village.id); // Use station() to properly set state
    updateArmy(army);

    if (army.owner == 'player') {
      addTurnEvent(VillageConqueredEvent(villageName: getVillageDisplayName(village)));
    }
  }

  void addTurnEvent(TurnEvent event) {
    turnEvents.add(event);
  }

  void clearTurnEvents() {
    turnEvents.clear();
  }


  double _getEffectiveVisionRange(Village village) {
    var range = visionRangeKm;
    final stationedArmies = getArmiesAt(village.id).where((a) => a.owner == village.owner);
    for (final army in stationedArmies) {
      if (army.units.any((u) => u.unitType == UnitType.lightCavalry)) {
        range += 200.0;
        break; // Doesn't stack
      }
    }
    return range;
  }

  bool isVillageInVisionRange(Village village, String playerId) {
    if (village.owner == playerId) return true;

    final playerVillages = getPlayerVillages(playerId);
    for (final pv in playerVillages) {
      final effectiveRange = _getEffectiveVisionRange(pv);
      final distKm = GeoCoordinate.distanceKm(pv.coordinates, village.coordinates);
      if (distKm <= effectiveRange) return true;
    }

    final playerArmies = getArmiesFor(playerId);
    for (final army in playerArmies) {
      if (army.stationedAt != null) {
        final stationedVillage = getVillageById(army.stationedAt);
        if (stationedVillage != null) {
          final effectiveRange = _getEffectiveVisionRange(stationedVillage);
          final distKm = GeoCoordinate.distanceKm(stationedVillage.coordinates, village.coordinates);
          if (distKm <= effectiveRange) return true;
        }
      }
    }
    return false;
  }

  Set<String> villageIdsInVisionRange(String playerId) {
    final sources = <(GeoCoordinate, double)>[];
    for (final pv in getPlayerVillages(playerId)) {
      sources.add((pv.coordinates, _getEffectiveVisionRange(pv)));
    }
    for (final army in getArmiesFor(playerId)) {
      if (army.stationedAt == null) continue;
      final stationedVillage = getVillageById(army.stationedAt);
      if (stationedVillage != null) {
        sources.add((stationedVillage.coordinates, _getEffectiveVisionRange(stationedVillage)));
      }
    }
    final ids = <String>{};
    for (final village in map.villages) {
      if (village.owner == playerId) {
        ids.add(village.id);
        continue;
      }
      for (final (coords, range) in sources) {
        if (GeoCoordinate.distanceKm(coords, village.coordinates) <= range) {
          ids.add(village.id);
          break;
        }
      }
    }
    return ids;
  }

  bool isVillageVisible(Village village, String playerId) {
    if (village.owner == playerId) return true;

    if (isVillageInVisionRange(village, playerId)) {
      discoveredVillageIDs.add(village.id);
      discoveredVillageCache[village.id] = DiscoveredVillageInfo(
        owner: village.owner,
        garrisonEstimate: _roundToNearest(getTotalDefenders(village), 5),
        turnSeen: currentTurn,
      );
      return true;
    }

    if (discoveredVillageIDs.contains(village.id)) return true;

    return false;
  }

  bool isArmyVisible(Army army, String playerId) {
    if (army.owner == playerId) return true;

    final locationId = army.stationedAt ?? army.destination;
    if (locationId == null) return false;

    final locationVillage = getVillageById(locationId);
    if (locationVillage == null) return false;

    final playerVillages = getPlayerVillages(playerId);
    for (final pv in playerVillages) {
      final effectiveRange = _getEffectiveVisionRange(pv);
      if (GeoCoordinate.distanceKm(pv.coordinates, locationVillage.coordinates) <= effectiveRange) {
        return true;
      }
    }

    final playerArmies = getArmiesFor(playerId);
    for (final pa in playerArmies) {
      if (pa.stationedAt != null) {
        final paVillage = getVillageById(pa.stationedAt);
        if (paVillage != null) {
          final effectiveRange = _getEffectiveVisionRange(paVillage);
          if (GeoCoordinate.distanceKm(paVillage.coordinates, locationVillage.coordinates) <= effectiveRange) {
            return true;
          }
        }
      }
    }
    return false;
  }

  void updateVisionCache(String playerId) {
    for (final village in map.villages) {
      if (village.owner == playerId) continue;
      if (isVillageInVisionRange(village, playerId)) {
        discoveredVillageIDs.add(village.id);
        discoveredVillageCache[village.id] = DiscoveredVillageInfo(
          owner: village.owner,
          garrisonEstimate: _roundToNearest(getTotalDefenders(village), 5),
          turnSeen: currentTurn,
        );
      }
    }
  }

  int _roundToNearest(int value, int nearest) {
    return ((value + nearest ~/ 2) ~/ nearest) * nearest;
  }

  List<Village> getVisibleVillages(String playerId) {
    return map.villages.where((v) => isVillageVisible(v, playerId)).toList();
  }

  List<Army> getVisibleArmies(String playerId) {
    return armies.where((a) => isArmyVisible(a, playerId)).toList();
  }

  int get conquestsInWindow {
    if (conquestTurns.length < 3) return 0;
    int maxInWindow = 0;
    for (var i = 0; i < conquestTurns.length; i++) {
      int count = 0;
      for (var j = i; j < conquestTurns.length; j++) {
        if (conquestTurns[j] - conquestTurns[i] <= 5) {
          count++;
        }
      }
      if (count > maxInWindow) maxInWindow = count;
    }
    return maxInWindow;
  }

  Player? getWinner() {
    if (achievedVictoryType != null) {
      final humanPlayer = players.firstWhere((p) => p.isHuman);
      if (!humanPlayer.isEliminated) return humanPlayer;
    }

    final activePlayers = players.where((p) => !p.isEliminated).toList();
    if (activePlayers.length == 1) return activePlayers.first;

    final humanPlayer = players.firstWhere((p) => p.isHuman);
    if (humanPlayer.isEliminated) {
      final activeAI = activePlayers.where((p) => !p.isHuman).toList();
      if (activeAI.isNotEmpty) {
        activeAI.sort((a, b) => getPlayerVillages(b.id).length.compareTo(getPlayerVillages(a.id).length));
        return activeAI.first;
      }
    }

    return null;
  }

  bool get isPlayerDefeated {
    final player = players.firstWhere((p) => p.isHuman);
    return player.isEliminated;
  }

  void finalizeBattle(BattleRecord record, int roundsPlayed, bool retreated) {
    final attacker = getArmyById(record.attackerId);

    Army? defenderArmy = getArmyById(record.defenderId);
    Village? defenderVillage;
    if (defenderArmy == null) {
      defenderVillage = getVillageById(record.defenderId);
    }

    if (attacker == null) {
      record.isPending = false;
      pendingBattles.removeWhere((b) => b.id == record.id);
      notifyListeners();
      return;
    }

    if (defenderArmy == null && defenderVillage == null) {
      record.isPending = false;
      pendingBattles.removeWhere((b) => b.id == record.id);
      notifyListeners();
      return;
    }

    if (attacker.units.isEmpty) {
      record.isPending = false;
      pendingBattles.removeWhere((b) => b.id == record.id);
      removeArmy(attacker.id);
      notifyListeners();
      return;
    }

    int attLosses = 0;
    int defLosses = 0;
    for (var i = 0; i < roundsPlayed && i < record.rounds.length; i++) {
      attLosses += record.rounds[i].attackerLosses;
      defLosses += record.rounds[i].defenderLosses;
    }

    final wasCavalryOnly = record.attackerOwnerId == 'player' && attacker.units.every((u) => u.unitType.category == 'Cavalry');

    _applyCasualtiesToArmy(attacker, attLosses);

    if (defenderArmy != null) {
      _applyCasualtiesToArmy(defenderArmy, defLosses);
      if (defenderArmy.units.isEmpty) {
        removeArmy(defenderArmy.id);
      } else {
        updateArmy(defenderArmy);
      }
    }

    if (defenderVillage != null && record.initialGarrisonCount > 0) {
      final armyUnitCount = record.initialDefenderCount - record.initialGarrisonCount;
      final garrisonLosses = max(0, defLosses - armyUnitCount);
      if (garrisonLosses > 0) {
        defenderVillage.damageGarrison(garrisonLosses);
      }
    }

    if (retreated) {
      if (attacker.units.isNotEmpty && record.originVillageId != null) {
        attacker.station(record.originVillageId!);
        updateArmy(attacker);
      } else if (attacker.units.isEmpty) {
        removeArmy(attacker.id);
      }
      if (defenderVillage != null) {
        defenderVillage.underSiege = false;
        updateVillage(defenderVillage);
      }
      if (record.attackerOwnerId == 'player') battlesLost++;
      addTurnEvent(BattleLostEvent(location: record.locationName, casualties: attLosses));
      record.isPending = false;
      pendingBattles.removeWhere((b) => b.id == record.id);
      notifyListeners();
      return;
    }

    final defenderWins = !record.attackerWon || attacker.units.isEmpty;

    final playerWasAttacker = record.attackerOwnerId == 'player';
    final playerWasDefender = record.defenderOwnerId == 'player';

    if (defenderWins) {
      battlesWon[record.defenderOwnerId] = (battlesWon[record.defenderOwnerId] ?? 0) + 1;
      if (playerWasAttacker) battlesLost++;
      removeArmy(attacker.id);
      if (defenderVillage != null) {
        defenderVillage.underSiege = false;
        updateVillage(defenderVillage);
      }
      if (playerWasAttacker) {
        addTurnEvent(BattleLostEvent(location: record.locationName, casualties: attLosses));
      } else if (playerWasDefender) {
        addTurnEvent(BattleWonEvent(location: record.locationName, casualties: defLosses));
      }
    } else {
      battlesWon[record.attackerOwnerId] = (battlesWon[record.attackerOwnerId] ?? 0) + 1;

      if (wasCavalryOnly) {
        hadCavalryOnlyBattleWin = true;
      }
      if (defenderVillage != null) {
        _conquerVillage(attacker, defenderVillage);
      } else if (defenderArmy != null) {
        updateArmy(attacker);
        if (playerWasAttacker) {
          addTurnEvent(BattleWonEvent(location: record.locationName, casualties: attLosses));
        } else if (playerWasDefender) {
          battlesLost++;
          addTurnEvent(BattleLostEvent(location: record.locationName, casualties: defLosses));
        }
      }
    }

    record.isPending = false;
    pendingBattles.removeWhere((b) => b.id == record.id);
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
      village.garrisonStrength = 0; // Reset garrison on conquest
      village.garrisonRegenAccumulator = 0.0;
      village.underSiege = false;
      updateVillage(village);

      final defenderArmies = armies.where((a) => a.stationedAt == village.id && a.owner == oldOwner).toList();
      for (final army in defenderArmies) {
        removeArmy(army.id);
      }

      attacker.station(village.id);
      updateArmy(attacker);

      pendingBattles.removeWhere((b) => b.defenderId == village.id && b.attackerId != attacker.id);

      if (attacker.owner == 'player') {
        conquestTurns.add(currentTurn);
        if (activeEvents.any((e) => e.type == GameEventType.harshWinter && e.isActive)) {
          conqueredDuringWinter = true;
        }
        addTurnEvent(VillageConqueredEvent(villageName: getVillageDisplayName(village)));
      } else if (oldOwner == 'player') {
        if (village.id == capitalVillageId) {
          lostCapital = true;
        }
        addTurnEvent(VillageLostEvent(villageName: getVillageDisplayName(village)));
      }
  }

  void cleanupStaleBattles() {
    pendingBattles.removeWhere((battle) {
      final attacker = getArmyById(battle.attackerId);
      if (attacker == null || attacker.units.isEmpty) {
        return true; // Remove this battle
      }

      final defenderArmy = getArmyById(battle.defenderId);
      final defenderVillage = getVillageById(battle.defenderId);
      if (defenderArmy == null && defenderVillage == null) {
        return true; // Remove this battle
      }

      if (defenderVillage != null && defenderVillage.owner == attacker.owner) {
        return true; // Remove - already conquered
      }

      return false; // Keep this battle
    });
  }

  void finalizeAIBattles() {
    final toFinalize = <BattleRecord>[];

    for (final battle in pendingBattles) {
      final playerInvolved = battle.attackerOwnerId == 'player' ||
                             battle.defenderOwnerId == 'player';

      if (!playerInvolved) {
        toFinalize.add(battle);
      }
    }

    for (final battle in toFinalize) {
      finalizeBattle(battle, battle.rounds.length, false);
    }
  }


  void Function() get onGameTickCallback => _onGameTick;
  void Function(String) get onPlayerArrivalCallback => _onPlayerArrival;

  void _onGameTick() {
    if (playerCharacter == null) return;

    final pc = playerCharacter!;

    String? arrivedAt;
    Encounter? encounter;
    if (pc.state == PlayerState.traveling) {
      pc.travelProgress += 1.0 / pc.travelTotalTicks;

      if (pc.travelProgress >= 1.0) {
        pc.travelProgress = 1.0;
        arrivedAt = pc.travelDestinationId!;
      } else {
        encounter = EncounterEngine.rollEncounter(
          playerWarband?.unitCount ?? 0,
          gameLoop.tickCount,
          tripTicks: pc.travelTotalTicks,
          scoutingSkill: pc.scoutingSkill,
        );
      }
    }

    if (gameLoop.tickCount % 5 == 0) {
      final warband = playerWarband;
      if (warband != null) {
        for (final u in warband.units) {
          u.heal(max(1, u.maxHP ~/ 20));
        }
        final upkeepGold = warband.unitCount * warbandWagePerMan;
        if (!spendGold(upkeepGold)) {
          if (warband.units.isNotEmpty) {
            warband.units.removeLast();
            if (warband.units.isEmpty) {
              removeArmy(warband.id);
            } else {
              updateArmy(warband);
            }
          }
        }
      }
    }

    if (gold <= 0 &&
        (playerWarband == null || playerWarband!.units.isEmpty) &&
        pc.currentCargoCount == 0 &&
        getPlayerVillages('player').isEmpty) {
      isGameOver = true;
      gameLoop.pause();
      notifyListeners();
      return;
    }

    if (gameLoop.tickCount % 5 == 0) {
      turnEngine.doTurn();
      if (arrivedAt == null) checkMissions();
    }

    if (arrivedAt != null) {
      _onPlayerArrival(arrivedAt);
    } else if (encounter != null) {
      currentEncounter = encounter;
      gameLoop.pause();
    }

    if (gameLoop.tickCount % 10 == 0) {
      SaveEngine.saveGame(this);
    }

    notifyListeners();
  }

  Timer? _citySaveTimer;

  @override
  void notifyListeners() {
    super.notifyListeners();
    if (gameStarted && playerCharacter != null && gameLoop.speed == GameSpeed.paused) {
      _citySaveTimer ??= Timer(const Duration(seconds: 2), () {
        _citySaveTimer = null;
        SaveEngine.saveGame(this);
      });
    }
  }

  @override
  void dispose() {
    _citySaveTimer?.cancel();
    campaignSaveFailed.dispose();
    super.dispose();
  }

  void _onPlayerArrival(String cityId) {
    final pc = playerCharacter!;
    pc.state = PlayerState.atCity;
    pc.currentCityId = cityId;
    pc.travelOriginId = null;
    pc.travelDestinationId = null;
    pc.travelProgress = 0.0;
    pc.travelTotalTicks = 0;

    final warband = playerWarband;
    if (warband != null) {
      warband.station(cityId);
      updateArmy(warband);
    }

    pc.checkProgression();
    checkMissions(cityId);
    gameLoop.pause();
    notifyListeners();
  }

  Army? get playerWarband => getArmyById(playerCharacter?.warbandId);

  static double fightingPower(Iterable<Unit> units) {
    var attack = 0.0;
    var hp = 0;
    for (final u in units) {
      final t = u.unitType;
      final volley = t.baseMissile * t.baseAccuracy / max(0.1, t.baseFireRate) * 1.3;
      attack += max(u.attack.toDouble(), volley) + t.baseCharge / 3;
      hp += u.currentHP;
    }
    return attack * hp;
  }

  EncounterBattleReport? lastBattleReport;

  static const encounterRoutBelow = 0.34;

  static const warbandWagePerMan = 2;


}

class EncounterBattleReport {
  final bool won;
  final BattlePlan plan;
  final int enemies;
  final int killed;
  final int wounded;
  final int goldGained;
  final int goldLost;
  final int cargoLost;

  const EncounterBattleReport({
    required this.won,
    required this.plan,
    required this.enemies,
    required this.killed,
    required this.wounded,
    required this.goldGained,
    required this.goldLost,
    required this.cargoLost,
  });
}

class DiscoveredVillageInfo {
  final String owner;
  final int garrisonEstimate;
  final int turnSeen;

  const DiscoveredVillageInfo({
    required this.owner,
    required this.garrisonEstimate,
    required this.turnSeen,
  });
}
