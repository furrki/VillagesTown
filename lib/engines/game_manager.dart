import 'dart:convert';
import 'dart:math';
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
import '../data/models/building.dart';
import '../data/models/combat_log.dart';
import '../data/models/difficulty.dart';
import '../data/models/game_event.dart';
import '../data/models/victory_condition.dart';
import '../data/models/village_trait.dart';
import 'combat_engine.dart';
import 'event_engine.dart';
import 'turn_engine.dart';

class GameManager extends ChangeNotifier {
  static final GameManager _instance = GameManager._internal();
  static GameManager get shared => _instance;
  factory GameManager() => _instance;
  GameManager._internal() {
    map = VirtualMap(villages: []);
  }

  // Connection settings
  static const int maxNeighborsPerCity = 4; // K-nearest neighbors
  static const double maxConnectionDistanceKm = 500.0; // Hard cap to prevent sea crossings

  // Pre-computed city connections (symmetric graph)
  Map<String, Set<String>> cityConnections = {};

  // State
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
  double visionRangeKm = 400.0; // Vision range in kilometers

  /// Cache of last-known info for discovered villages (stale data for fog of war).
  /// Key: village ID, Value: (owner, garrison estimate, turn last seen)
  Map<String, DiscoveredVillageInfo> discoveredVillageCache = {};

  // Victory tracking
  VictoryType? selectedVictoryType;
  Map<String, int> battlesWon = {};
  VictoryType? achievedVictoryType;

  // World events
  List<GameEvent> activeEvents = [];
  List<GameEvent> eventHistory = [];

  // Difficulty
  Difficulty? difficulty;

  // Achievement tracking (per-game stats)
  int battlesLost = 0;
  int peakGold = 0;
  int peakVillageCount = 0;
  bool lostCapital = false;
  bool hadCavalryOnlyBattleWin = false;
  bool conqueredDuringWinter = false;
  List<int> conquestTurns = []; // turns when villages were conquered

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

    // Set up player with chosen nationality
    players[0] = players[0].copyWith(nationality: nationality);

    // Find which AI player matches the chosen nationality and eliminate them
    // (player takes their faction slot)
    for (var i = 1; i < players.length; i++) {
      if (players[i].nationality.id == nationality.id) {
        players[i] = players[i].copyWith(isEliminated: true);
        break;
      }
    }

    // Build all cities
    final allVillages = _buildAllCities(nationality);

    map = VirtualMap(villages: allVillages);

    // Load custom territories from asset
    _loadTerritories(allVillages);

    // Build city connection graph
    _buildCityConnections();

    // Update player village lists
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

    // Helper to get owner ID for a nationality
    String getOwner(Nationality nat) {
      if (nat.id == playerNationality.id) return 'player';
      // Match to AI player by nationality id
      for (final p in players) {
        if (!p.isHuman && p.nationality.id == nat.id) return p.id;
      }
      return 'neutral';
    }

    // === MAJOR FACTION CAPITALS (stronger) ===
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

    // === MINOR FACTION CAPITALS (weaker) ===
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

    // === MAJOR FACTION SECONDARY CITIES ===
    // Byzantine secondary cities
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

    // Ottoman secondary cities
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

    // Crusader secondary cities
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

    // === MINOR FACTION SECONDARY CITIES ===
    // Bulgarian
    villages.add(Village(
      name: 'Sofia', nationality: Nationality.bulgaria,
      coordinates: const GeoCoordinate(42.6977, 23.3219),
      owner: getOwner(Nationality.bulgaria),
      garrisonStrength: 8, garrisonMaxStrength: 15,
    ));

    // Serbian
    villages.add(Village(
      name: 'Nis', nationality: Nationality.serbia,
      coordinates: const GeoCoordinate(43.3209, 21.8954),
      owner: getOwner(Nationality.serbia),
      garrisonStrength: 8, garrisonMaxStrength: 15,
    ));

    // Armenian
    villages.add(Village(
      name: 'Van', nationality: Nationality.armenia,
      coordinates: const GeoCoordinate(38.4891, 43.4089),
      owner: getOwner(Nationality.armenia),
      garrisonStrength: 8, garrisonMaxStrength: 15,
    ));

    // Mamluk
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

    // === NEUTRAL CITIES (contested territories) ===
    // Anatolia
    villages.add(Village(name: 'Smyrna', nationality: Nationality.byzantines, coordinates: const GeoCoordinate(38.4237, 27.1428), owner: 'neutral'));
    villages.add(Village(name: 'Trebizond', nationality: Nationality.byzantines, coordinates: const GeoCoordinate(41.0027, 39.7168), owner: 'neutral'));
    villages.add(Village(name: 'Sinope', nationality: Nationality.byzantines, coordinates: const GeoCoordinate(42.0231, 35.1531), owner: 'neutral'));
    villages.add(Village(name: 'Edirne', nationality: Nationality.ottomans, coordinates: const GeoCoordinate(41.6771, 26.5557), owner: 'neutral'));
    villages.add(Village(name: 'Erzurum', nationality: Nationality.armenia, coordinates: const GeoCoordinate(39.9043, 41.2679), owner: 'neutral'));

    // Balkans
    villages.add(Village(name: 'Athens', nationality: Nationality.byzantines, coordinates: const GeoCoordinate(37.9838, 23.7275), owner: 'neutral'));
    villages.add(Village(name: 'Skopje', nationality: Nationality.serbia, coordinates: const GeoCoordinate(41.9981, 21.4254), owner: 'neutral'));
    villages.add(Village(name: 'Plovdiv', nationality: Nationality.bulgaria, coordinates: const GeoCoordinate(42.1354, 24.7453), owner: 'neutral'));

    // Levant
    villages.add(Village(name: 'Aleppo', nationality: Nationality.mamluks, coordinates: const GeoCoordinate(36.2021, 37.1343), owner: 'neutral'));
    villages.add(Village(name: 'Tripoli', nationality: Nationality.crusaders, coordinates: const GeoCoordinate(34.4367, 35.8497), owner: 'neutral'));
    villages.add(Village(name: 'Gaza', nationality: Nationality.mamluks, coordinates: const GeoCoordinate(31.5, 34.4667), owner: 'neutral'));

    // Islands
    villages.add(Village(name: 'Rhodes', nationality: Nationality.crusaders, coordinates: const GeoCoordinate(36.4349, 28.2176), owner: 'neutral'));
    villages.add(Village(name: 'Crete', nationality: Nationality.byzantines, coordinates: const GeoCoordinate(35.2401, 24.8093), owner: 'neutral'));
    villages.add(Village(name: 'Cyprus', nationality: Nationality.crusaders, coordinates: const GeoCoordinate(35.1264, 33.4299), owner: 'neutral'));

    // Caucasus
    villages.add(Village(name: 'Kars', nationality: Nationality.armenia, coordinates: const GeoCoordinate(40.6013, 43.0975), owner: 'neutral'));

    // Assign village traits based on geography
    _assignVillageTraits(villages);

    return villages;
  }

  void _assignVillageTraits(List<Village> villages) {
    const traitMap = <String, VillageTrait>{
      // Fertile: river valleys and plains
      'Cairo': VillageTrait.fertile,
      'Damascus': VillageTrait.fertile,
      'Alexandria': VillageTrait.fertile,
      'Thessaloniki': VillageTrait.fertile,
      'Gaza': VillageTrait.fertile,
      // Forested: wooded regions
      'Sofia': VillageTrait.forested,
      'Tarnovo': VillageTrait.forested,
      'Belgrade': VillageTrait.forested,
      'Nis': VillageTrait.forested,
      // Mountainous: highland/mountain regions
      'Van': VillageTrait.mountainous,
      'Kars': VillageTrait.mountainous,
      'Ani': VillageTrait.mountainous,
      'Erzurum': VillageTrait.mountainous,
      'Konya': VillageTrait.mountainous,
      // Trade crossroads: major trade hubs
      'Constantinople': VillageTrait.tradeCrossroads,
      'Antioch': VillageTrait.tradeCrossroads,
      'Aleppo': VillageTrait.tradeCrossroads,
      'Bursa': VillageTrait.tradeCrossroads,
      // Coastal: port cities
      'Acre': VillageTrait.coastal,
      'Smyrna': VillageTrait.coastal,
      'Trebizond': VillageTrait.coastal,
      'Sinope': VillageTrait.coastal,
      'Tripoli': VillageTrait.coastal,
      'Rhodes': VillageTrait.coastal,
      'Crete': VillageTrait.coastal,
      'Cyprus': VillageTrait.coastal,
      // Strategic: defensible positions
      'Jerusalem': VillageTrait.strategic,
      'Nicaea': VillageTrait.strategic,
      'Ankara': VillageTrait.strategic,
      'Edirne': VillageTrait.strategic,
      // Remaining get none by default
    };

    for (final village in villages) {
      village.trait = traitMap[village.name] ?? VillageTrait.none;
    }
  }

  /// Build K-nearest neighbor connections for all cities
  void _buildCityConnections() {
    cityConnections.clear();

    // Step 1: For each city, find its K nearest neighbors (within max distance)
    for (final village in map.villages) {
      final candidates = <(Village, double)>[];

      for (final other in map.villages) {
        if (other.id == village.id) continue;
        final dist = GeoCoordinate.distanceKm(village.coordinates, other.coordinates);
        if (dist <= maxConnectionDistanceKm) {
          candidates.add((other, dist));
        }
      }

      // Sort by distance, take closest K
      candidates.sort((a, b) => a.$2.compareTo(b.$2));
      final neighbors = candidates.take(maxNeighborsPerCity).map((c) => c.$1.id).toSet();
      cityConnections[village.id] = neighbors;
    }

    // Step 2: Ensure symmetry - if A connects to B, B must connect to A
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

    // Apply difficulty starting gold bonus
    final goldBonus = difficulty?.playerStartGoldBonus ?? 0;
    if (goldBonus != 0) {
      modifyGlobalResource('player', Resource.gold, goldBonus);
    }

    notifyListeners();
  }

  void resetGame() {
    gameStarted = false;
    currentTurn = 0;
    currentPlayer = 'player';
    playerNationality = null;
    armies.clear();
    turnEvents.clear();
    globalResources.clear();
    discoveredVillageIDs.clear();
    discoveredVillageCache.clear();
    pendingBattles.clear();
    cityConnections.clear();
    tutorialEnabled = true;
    tutorialStep = 0;
    completedTutorialActions.clear();
    selectedVictoryType = null;
    battlesWon.clear();
    achievedVictoryType = null;
    activeEvents.clear();
    eventHistory.clear();
    difficulty = null;
    battlesLost = 0;
    peakGold = 0;
    peakVillageCount = 0;
    lostCapital = false;
    hadCavalryOnlyBattleWin = false;
    conqueredDuringWinter = false;
    conquestTurns.clear();

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

  // Get nationality for a player/owner ID
  Nationality? getNationality(String ownerId) {
    if (ownerId == 'neutral') return null;
    final player = players.cast<Player?>().firstWhere(
      (p) => p?.id == ownerId,
      orElse: () => null,
    );
    return player?.nationality;
  }

  // Get display name for a village based on current owner
  String getVillageDisplayName(Village village) {
    return village.displayName(getNationality(village.owner));
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

  /// Get total defender count for a village (garrison + stationed army units)
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

  /// Get all armies currently besieging a village
  List<Army> getBesiegingArmiesAt(String villageId) {
    return armies.where((a) => a.stationedAt == villageId && a.state == ArmyState.besieging).toList();
  }

  /// Get villages under siege by a specific player
  List<Village> getSiegedVillagesFor(String playerId) {
    return map.villages.where((v) {
      final besiegers = getBesiegingArmiesAt(v.id);
      return besiegers.any((a) => a.owner == playerId);
    }).toList();
  }

  /// Get villages owned by player that are under siege
  List<Village> getVillagesUnderSiegeFor(String playerId) {
    return map.villages.where((v) {
      return v.owner == playerId && getBesiegingArmiesAt(v.id).isNotEmpty;
    }).toList();
  }

  Army createArmy(List<Unit> units, String villageId, String owner) {
    final village = map.villages.cast<Village?>().firstWhere(
      (v) => v?.id == villageId,
      orElse: () => null,
    );
    // Use OWNER's nationality for the army name, not village's
    final ownerPlayer = players.cast<Player?>().firstWhere(
      (p) => p?.id == owner,
      orElse: () => null,
    );
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

    // Sort by unit count descending - largest army keeps its name
    armiesHere.sort((a, b) => b.units.length.compareTo(a.units.length));
    final primary = armiesHere.first;

    // Collect all units from other armies
    final unitsToAdd = <Unit>[];
    for (var i = 1; i < armiesHere.length; i++) {
      unitsToAdd.addAll(armiesHere[i].units);
      removeArmy(armiesHere[i].id);
    }

    // Add units to primary army (preserves its name and ID)
    primary.units.addAll(unitsToAdd);
    updateArmy(primary);
  }

  /// Defender sallies out to fight besiegers in the field (no fortress bonus)
  /// Returns the battle record if sally was successful
  BattleRecord? sallyOut(String villageId) {
    final village = map.villages.cast<Village?>().firstWhere(
      (v) => v!.id == villageId,
      orElse: () => null,
    );
    if (village == null) return null;

    final besiegers = getBesiegingArmiesAt(villageId);
    if (besiegers.isEmpty) return null;

    // Get all defenders (garrison + stationed armies)
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

    // Combine all besieging armies
    final attackerUnits = besiegers.expand((a) => a.units).toList();
    if (attackerUnits.isEmpty) return null;

    // Create a field battle (NO fortress bonus - sallyOut negates it)
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
      pendingBattles.add(result);
      village.underSiege = false; // Battle resolving the siege

      // Reset besiegers to stationed state (battle will determine outcome)
      for (final army in besiegers) {
        army.state = ArmyState.stationed;
        army.siegeTurns = 0;
      }

      addTurnEvent(GeneralEvent(text: '${village.name} garrison sallied out!'));
      notifyListeners();
      return result;
    }
    return null;
  }

  /// Send army to intercept a marching enemy army
  /// Returns true if interception was set up successfully
  bool interceptArmy(String interceptorId, String targetArmyId) {
    final interceptor = armies.cast<Army?>().firstWhere(
      (a) => a!.id == interceptorId,
      orElse: () => null,
    );
    if (interceptor == null) return false;

    // Interceptor must be stationed
    if (interceptor.state != ArmyState.stationed) return false;
    if (interceptor.stationedAt == null) return false;

    final target = armies.cast<Army?>().firstWhere(
      (a) => a!.id == targetArmyId,
      orElse: () => null,
    );
    if (target == null) return false;

    // Target must be marching and enemy
    if (!target.isMarching) return false;
    if (target.owner == interceptor.owner) return false;

    // Check if interceptor can reach target's path
    // Interceptor must be adjacent to target's destination
    final targetDest = target.destination;
    if (targetDest == null) return false;
    if (!areNeighbors(interceptor.stationedAt!, targetDest)) return false;

    // Send interceptor to target's destination - they'll meet there
    final destination = map.villages.cast<Village?>().firstWhere(
      (v) => v!.id == targetDest,
      orElse: () => null,
    );
    if (destination == null) return false;

    final originVillage = map.villages.cast<Village?>().firstWhere(
      (v) => v!.id == interceptor.stationedAt,
      orElse: () => null,
    );
    if (originVillage == null) return false;

    // Calculate turns to intercept (try to arrive same time or earlier)
    final turns = Army.calculateTravelTime(originVillage.coordinates, destination.coordinates);
    interceptor.marchTo(targetDest, min(turns, target.turnsUntilArrival), interceptor.stationedAt);
    updateArmy(interceptor);

    addTurnEvent(GeneralEvent(text: '${interceptor.name} moving to intercept ${target.name}'));
    notifyListeners();
    return true;
  }

  /// Check if two villages are neighbors (using pre-computed K-nearest graph)
  bool areNeighbors(String villageId1, String villageId2) {
    return cityConnections[villageId1]?.contains(villageId2) ?? false;
  }

  /// Get all neighbors of a village (using pre-computed K-nearest graph)
  List<Village> getNeighbors(String villageId) {
    final neighborIds = cityConnections[villageId];
    if (neighborIds == null) return [];
    return map.villages.where((v) => neighborIds.contains(v.id)).toList();
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

    // Check if destination is a neighbor
    if (!areNeighbors(origin, destinationVillageId)) return false;

    final originVillage = map.villages.cast<Village?>().firstWhere(
          (v) => v!.id == origin,
          orElse: () => null,
        );
    if (originVillage == null) return false;

    final army = armies[armyIndex];

    // Check for undefended village - instant capture
    if (destination.owner != army.owner) {
      final defendingArmies = getArmiesAt(destination.id).where((a) => a.owner == destination.owner).toList();
      final hasDefenders = destination.garrisonStrength > 0 || defendingArmies.isNotEmpty;

      if (!hasDefenders) {
        // No defenders - instant capture (no siege needed)
        _captureUndefendedVillage(army, destination, origin);
        notifyListeners();
        return true;
      }
    }

    // March to destination (friendly or enemy - siege mechanics handled by turn engine)
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

  // Turn Events
  void addTurnEvent(TurnEvent event) {
    turnEvents.add(event);
  }

  void clearTurnEvents() {
    turnEvents.clear();
  }

  // Fog of War

  /// Get effective vision range for a village (base + light cavalry scouting bonus).
  double _getEffectiveVisionRange(Village village) {
    var range = visionRangeKm;
    // Light Cavalry scouting: +200km vision (doesn't stack)
    final stationedArmies = getArmiesAt(village.id).where((a) => a.owner == village.owner);
    for (final army in stationedArmies) {
      if (army.units.any((u) => u.unitType == UnitType.lightCavalry)) {
        range += 200.0;
        break; // Doesn't stack
      }
    }
    return range;
  }

  /// Check if a village is currently in vision range (not just discovered).
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
        final stationedVillage = map.villages.cast<Village?>().firstWhere(
              (v) => v!.id == army.stationedAt,
              orElse: () => null,
            );
        if (stationedVillage != null) {
          final effectiveRange = _getEffectiveVisionRange(stationedVillage);
          final distKm = GeoCoordinate.distanceKm(stationedVillage.coordinates, village.coordinates);
          if (distKm <= effectiveRange) return true;
        }
      }
    }
    return false;
  }

  bool isVillageVisible(Village village, String playerId) {
    if (village.owner == playerId) return true;

    if (isVillageInVisionRange(village, playerId)) {
      discoveredVillageIDs.add(village.id);
      // Update cache with current data
      discoveredVillageCache[village.id] = DiscoveredVillageInfo(
        owner: village.owner,
        garrisonEstimate: _roundToNearest(getTotalDefenders(village), 5),
        turnSeen: currentTurn,
      );
      return true;
    }

    // Previously discovered but out of range = still visible (stale data)
    if (discoveredVillageIDs.contains(village.id)) return true;

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
      final effectiveRange = _getEffectiveVisionRange(pv);
      if (GeoCoordinate.distanceKm(pv.coordinates, locationVillage.coordinates) <= effectiveRange) {
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

  /// Update vision cache for all villages in range at start of turn.
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

  /// Max conquests within any 5-turn window (for blitzkrieg achievement).
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

  // Victory/Defeat
  Player? getWinner() {
    // Check if player achieved a victory condition
    if (achievedVictoryType != null) {
      final humanPlayer = players.firstWhere((p) => p.isHuman);
      if (!humanPlayer.isEliminated) return humanPlayer;
    }

    // Classic elimination: last player standing
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

    Army? defenderArmy = armies.cast<Army?>().firstWhere((a) => a!.id == record.defenderId, orElse: () => null);
    Village? defenderVillage;
    if (defenderArmy == null) {
      defenderVillage = map.villages.cast<Village?>().firstWhere((v) => v!.id == record.defenderId, orElse: () => null);
    }

    // Verify participants exist - clean up stale battle if not
    if (attacker == null) {
      record.isPending = false;
      pendingBattles.removeWhere((b) => b.id == record.id);
      notifyListeners();
      return;
    }

    if (defenderArmy == null && defenderVillage == null) {
      // Defender no longer exists - clean up
      record.isPending = false;
      pendingBattles.removeWhere((b) => b.id == record.id);
      notifyListeners();
      return;
    }

    // Verify attacker still has units
    if (attacker.units.isEmpty) {
      record.isPending = false;
      pendingBattles.removeWhere((b) => b.id == record.id);
      removeArmy(attacker.id);
      notifyListeners();
      return;
    }

    // 2. Calculate losses from rounds played
    int attLosses = 0;
    int defLosses = 0;
    for (var i = 0; i < roundsPlayed && i < record.rounds.length; i++) {
      attLosses += record.rounds[i].attackerLosses;
      defLosses += record.rounds[i].defenderLosses;
    }

    // 3. Apply Losses to armies and garrison
    _applyCasualtiesToArmy(attacker, attLosses);

    if (defenderArmy != null) {
      _applyCasualtiesToArmy(defenderArmy, defLosses);
      if (defenderArmy.units.isEmpty) {
        removeArmy(defenderArmy.id);
      } else {
        updateArmy(defenderArmy);
      }
    }

    // Apply garrison casualties (garrison takes losses after army units)
    if (defenderVillage != null && record.initialGarrisonCount > 0) {
      final armyUnitCount = record.initialDefenderCount - record.initialGarrisonCount;
      final garrisonLosses = max(0, defLosses - armyUnitCount);
      if (garrisonLosses > 0) {
        defenderVillage.damageGarrison(garrisonLosses);
      }
    }

    // 4. Handle Retreat - attacker returns home
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
      addTurnEvent(BattleLostEvent(location: record.locationName, casualties: attLosses));
      record.isPending = false;
      pendingBattles.removeWhere((b) => b.id == record.id);
      notifyListeners();
      return;
    }

    // 5. Use combat engine's winner determination (authoritative)
    // Defender wins if combat engine said so, or if attacker has no units left
    final defenderWins = !record.attackerWon || attacker.units.isEmpty;

    // Determine if player was involved and their role
    final playerWasAttacker = record.attackerOwnerId == 'player';
    final playerWasDefender = record.defenderOwnerId == 'player';

    // 6. Handle outcomes
    if (defenderWins) {
      // Attacker lost - defender gets battle win credit
      battlesWon[record.defenderOwnerId] = (battlesWon[record.defenderOwnerId] ?? 0) + 1;
      if (playerWasAttacker) battlesLost++;
      removeArmy(attacker.id);
      if (defenderVillage != null) {
        defenderVillage.underSiege = false;
        updateVillage(defenderVillage);
      }
      // Event from player's perspective
      if (playerWasAttacker) {
        addTurnEvent(BattleLostEvent(location: record.locationName, casualties: attLosses));
      } else if (playerWasDefender) {
        addTurnEvent(BattleWonEvent(location: record.locationName, casualties: defLosses));
      }
    } else {
      // Attacker won - attacker gets battle win credit
      battlesWon[record.attackerOwnerId] = (battlesWon[record.attackerOwnerId] ?? 0) + 1;

      // Track cavalry-only win for achievement
      if (playerWasAttacker && attacker.units.every((u) => u.unitType.category == 'Cavalry')) {
        hadCavalryOnlyBattleWin = true;
      }
      if (defenderVillage != null) {
        // Siege victory - conquer (this also updates the army and adds event)
        _conquerVillage(attacker, defenderVillage);
      } else if (defenderArmy != null) {
        // Field battle victory
        updateArmy(attacker);
        // Event from player's perspective
        if (playerWasAttacker) {
          addTurnEvent(BattleWonEvent(location: record.locationName, casualties: attLosses));
        } else if (playerWasDefender) {
          addTurnEvent(BattleLostEvent(location: record.locationName, casualties: defLosses));
        }
      }
    }

    // 7. Clean up record
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

      // Remove or rout any defender armies that were stationed here
      final defenderArmies = armies.where((a) => a.stationedAt == village.id && a.owner == oldOwner).toList();
      for (final army in defenderArmies) {
        removeArmy(army.id);
      }

      // Station attacking army
      attacker.station(village.id);
      updateArmy(attacker);

      // Clean up any other pending battles involving this village
      // (e.g., multiple armies attacked same village, first one conquered it)
      pendingBattles.removeWhere((b) => b.defenderId == village.id && b.attackerId != attacker.id);

      if (attacker.owner == 'player') {
        conquestTurns.add(currentTurn);
        if (activeEvents.any((e) => e.type == GameEventType.harshWinter && e.isActive)) {
          conqueredDuringWinter = true;
        }
        addTurnEvent(VillageConqueredEvent(villageName: getVillageDisplayName(village)));
      } else if (oldOwner == 'player') {
        // Check if player lost their capital (first village of their nationality)
        if (village.nationality == playerNationality) {
          lostCapital = true;
        }
        addTurnEvent(VillageLostEvent(villageName: getVillageDisplayName(village)));
      }
  }

  /// Clean up stale battles where participants no longer exist
  void cleanupStaleBattles() {
    pendingBattles.removeWhere((battle) {
      // Check if attacker army still exists and has units
      final attacker = armies.cast<Army?>().firstWhere(
        (a) => a!.id == battle.attackerId,
        orElse: () => null,
      );
      if (attacker == null || attacker.units.isEmpty) {
        return true; // Remove this battle
      }

      // Check if defender still exists (army or village)
      final defenderArmy = armies.cast<Army?>().firstWhere(
        (a) => a!.id == battle.defenderId,
        orElse: () => null,
      );
      final defenderVillage = map.villages.cast<Village?>().firstWhere(
        (v) => v!.id == battle.defenderId,
        orElse: () => null,
      );
      if (defenderArmy == null && defenderVillage == null) {
        return true; // Remove this battle
      }

      // Check if village ownership changed (conquest already happened)
      if (defenderVillage != null && defenderVillage.owner == attacker.owner) {
        return true; // Remove - already conquered
      }

      return false; // Keep this battle
    });
  }

  /// Auto-finalize battles that don't involve the player
  void finalizeAIBattles() {
    final toFinalize = <BattleRecord>[];

    for (final battle in pendingBattles) {
      // Use stored owner IDs from battle creation time (not current ownership!)
      final playerInvolved = battle.attackerOwnerId == 'player' ||
                             battle.defenderOwnerId == 'player';

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

/// Cached info about a discovered village (for fog of war stale data).
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
