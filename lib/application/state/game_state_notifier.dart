import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/types/typed_ids.dart';
import '../../domain/entities/army.dart';
import '../../domain/entities/building.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/entities/player.dart';
import '../../domain/entities/unit.dart';
import '../../domain/entities/village.dart';
import '../../domain/value_objects/geo_coordinate.dart';
import '../../domain/value_objects/resources.dart';

/// Central state notifier for the entire game.
/// All game state modifications go through this class.
class GameStateNotifier extends StateNotifier<GameState> {
  GameStateNotifier() : super(GameState.initial());

  /// Expose current state for use cases.
  /// Prefer using providers for reactive access in widgets.
  GameState get currentState => state;

  // === Game Setup ===

  void setupGame(NationalityId playerNationality) {
    final players = _createPlayers(playerNationality);
    final villages = _createVillages();
    final connections = _buildConnections(villages);

    state = state.copyWith(
      players: {for (final p in players) p.id: p},
      villages: {for (final v in villages) v.id: v},
      connections: connections,
      gameStarted: false,
    );

    _assignStartingVillages();
    _syncGlobalResources();
  }

  void startGame() {
    state = state.copyWith(gameStarted: true);
  }

  // === Village Operations ===

  void updateVillage(Village village) {
    state = state.updateVillage(village);
  }

  void transferVillageOwnership(VillageId villageId, PlayerId newOwner) {
    final village = state.getVillage(villageId);
    if (village == null) return;

    final updated = village.copyWith(owner: newOwner);
    state = state.updateVillage(updated);
    _syncGlobalResources();
  }

  void modifyGarrison(VillageId villageId, int delta) {
    final village = state.getVillage(villageId);
    if (village == null) return;

    final newStrength = (village.garrisonStrength + delta)
        .clamp(0, village.garrisonMaxStrength);
    state = state.updateVillage(village.copyWith(garrisonStrength: newStrength));
  }

  void addBuildingToVillage(VillageId villageId, BuildingType type) {
    final village = state.getVillage(villageId);
    if (village == null || !village.canBuildMore) return;

    final building = Building.create(type);
    final updated = village.copyWith(
      buildings: [...village.buildings, building],
    );
    state = state.updateVillage(updated);
  }

  // === Army Operations ===

  void addArmy(Army army) {
    state = state.addArmy(army);
  }

  void updateArmy(Army army) {
    state = state.updateArmy(army);
  }

  void removeArmy(ArmyId armyId) {
    state = state.removeArmy(armyId);
  }

  void createArmy({
    required List<Unit> units,
    required PlayerId owner,
    required VillageId stationedAt,
  }) {
    final village = state.getVillage(stationedAt);
    final army = Army.create(
      units: units,
      owner: owner,
      stationedAt: stationedAt,
      villageName: village?.name ?? 'Unknown',
      nationalityId: village?.originalNationality.value ?? 'crusader',
    );
    state = state.addArmy(army);
  }

  void addUnitsToArmy(ArmyId armyId, List<Unit> units) {
    final army = state.getArmy(armyId);
    if (army == null) return;

    state = state.updateArmy(army.addUnits(units));
  }

  void sendArmy(ArmyId armyId, VillageId destination, int turns) {
    final army = state.getArmy(armyId);
    if (army == null) return;

    state = state.updateArmy(army.marchTo(destination, turns));
  }

  void advanceAllArmies() {
    for (final army in state.armies.values) {
      if (army.isMarching) {
        state = state.updateArmy(army.advanceMarch());
      }
    }
  }

  void mergeArmiesAt(VillageId villageId, PlayerId owner) {
    final armiesHere = state.armies.values
        .where((a) => a.stationedAt == villageId && a.owner == owner)
        .toList();

    if (armiesHere.length <= 1) return;

    // Sort by unit count descending - largest army keeps its name
    armiesHere.sort((a, b) => b.units.length.compareTo(a.units.length));
    final primary = armiesHere.first;
    final allUnits = armiesHere.expand((a) => a.units).toList();

    // Remove all but primary
    for (var i = 1; i < armiesHere.length; i++) {
      state = state.removeArmy(armiesHere[i].id);
    }

    // Update primary with all units (preserves its name)
    state = state.updateArmy(primary.copyWith(units: allUnits));
  }

  // === Resource Operations ===

  void modifyResources(PlayerId playerId, ResourceBundle delta) {
    final current = state.globalResources[playerId] ?? ResourceBundle.empty;
    state = state.setGlobalResources(playerId, current + delta);
  }

  void setResources(PlayerId playerId, ResourceBundle resources) {
    state = state.setGlobalResources(playerId, resources);
  }

  void _syncGlobalResources() {
    final resources = <PlayerId, ResourceBundle>{};
    for (final player in state.players.values) {
      if (player.isNeutral) continue;
      var total = ResourceBundle.empty;
      for (final village in state.getPlayerVillages(player.id)) {
        total = total + village.resources;
      }
      resources[player.id] = total;
    }
    state = state.copyWith(globalResources: resources);
  }

  // === Battle Operations ===

  void addPendingBattle(BattleRecord battle) {
    state = state.addPendingBattle(battle);
  }

  void removePendingBattle(BattleId battleId) {
    state = state.removePendingBattle(battleId);
  }

  void markBattleResolved(BattleId battleId) {
    final battle = state.pendingBattles.where((b) => b.id == battleId).firstOrNull;
    if (battle == null) return;

    final resolved = battle.copyWith(isPending: false);
    state = state.copyWith(
      pendingBattles: state.pendingBattles
          .map((b) => b.id == battleId ? resolved : b)
          .toList(),
    );
  }

  // === Player Operations ===

  void eliminatePlayer(PlayerId playerId) {
    final player = state.getPlayer(playerId);
    if (player == null) return;

    state = state.updatePlayer(player.copyWith(isEliminated: true));

    // Remove all their armies
    for (final army in state.getPlayerArmies(playerId)) {
      state = state.removeArmy(army.id);
    }
  }

  void checkVictory() {
    final active = state.activePlayers;
    if (active.length == 1) {
      state = state.setWinner(active.first.id);
    }
  }

  // === Turn Operations ===

  void incrementTurn() {
    state = state.incrementTurn();
  }

  void discoverVillage(VillageId villageId) {
    state = state.discoverVillage(villageId);
  }

  // === Private Helpers ===

  List<Player> _createPlayers(NationalityId humanNationality) {
    return Player.createAllPlayers(humanNationality);
  }

  List<Village> _createVillages() {
    // Major faction capitals
    final villages = <Village>[
      // Byzantine
      Village.create(
        name: 'Constantinople',
        originalNationality: NationalityId.byzantine,
        coordinates: const GeoCoordinate(latitude: 41.0082, longitude: 28.9784),
        owner: PlayerId.byzantine,
      ),
      // Ottoman
      Village.create(
        name: 'Bursa',
        originalNationality: NationalityId.ottoman,
        coordinates: const GeoCoordinate(latitude: 40.1885, longitude: 29.0610),
        owner: PlayerId.ottoman,
      ),
      // Crusader
      Village.create(
        name: 'Acre',
        originalNationality: NationalityId.crusader,
        coordinates: const GeoCoordinate(latitude: 32.9231, longitude: 35.0680),
        owner: PlayerId.crusader,
      ),
      // Minor faction capitals
      Village.create(
        name: 'Tarnovo',
        originalNationality: NationalityId.bulgarian,
        coordinates: const GeoCoordinate(latitude: 43.0757, longitude: 25.6172),
        owner: PlayerId.bulgarian,
      ),
      Village.create(
        name: 'Belgrade',
        originalNationality: NationalityId.serbian,
        coordinates: const GeoCoordinate(latitude: 44.7866, longitude: 20.4489),
        owner: PlayerId.serbian,
      ),
      Village.create(
        name: 'Ani',
        originalNationality: NationalityId.armenian,
        coordinates: const GeoCoordinate(latitude: 40.5061, longitude: 43.5728),
        owner: PlayerId.armenian,
      ),
      Village.create(
        name: 'Cairo',
        originalNationality: NationalityId.mamluk,
        coordinates: const GeoCoordinate(latitude: 30.0444, longitude: 31.2357),
        owner: PlayerId.mamluk,
      ),
      // Secondary cities
      Village.create(
        name: 'Thessaloniki',
        originalNationality: NationalityId.byzantine,
        coordinates: const GeoCoordinate(latitude: 40.6401, longitude: 22.9444),
        owner: PlayerId.byzantine,
      ),
      Village.create(
        name: 'Athens',
        originalNationality: NationalityId.byzantine,
        coordinates: const GeoCoordinate(latitude: 37.9838, longitude: 23.7275),
        owner: PlayerId.byzantine,
      ),
      Village.create(
        name: 'Nicaea',
        originalNationality: NationalityId.byzantine,
        coordinates: const GeoCoordinate(latitude: 40.4292, longitude: 29.7211),
        owner: PlayerId.ottoman,
      ),
      Village.create(
        name: 'Konya',
        originalNationality: NationalityId.ottoman,
        coordinates: const GeoCoordinate(latitude: 37.8746, longitude: 32.4932),
        owner: PlayerId.ottoman,
      ),
      Village.create(
        name: 'Antioch',
        originalNationality: NationalityId.crusader,
        coordinates: const GeoCoordinate(latitude: 36.2000, longitude: 36.1500),
        owner: PlayerId.crusader,
      ),
      Village.create(
        name: 'Jerusalem',
        originalNationality: NationalityId.crusader,
        coordinates: const GeoCoordinate(latitude: 31.7683, longitude: 35.2137),
        owner: PlayerId.crusader,
      ),
      // Neutral contested cities
      Village.create(
        name: 'Edirne',
        originalNationality: NationalityId.byzantine,
        coordinates: const GeoCoordinate(latitude: 41.6771, longitude: 26.5557),
        owner: PlayerId.neutral,
      ),
      Village.create(
        name: 'Sofia',
        originalNationality: NationalityId.bulgarian,
        coordinates: const GeoCoordinate(latitude: 42.6977, longitude: 23.3219),
        owner: PlayerId.neutral,
      ),
      Village.create(
        name: 'Damascus',
        originalNationality: NationalityId.mamluk,
        coordinates: const GeoCoordinate(latitude: 33.5138, longitude: 36.2765),
        owner: PlayerId.neutral,
      ),
    ];
    return villages;
  }

  Map<VillageId, Set<VillageId>> _buildConnections(List<Village> villages) {
    const maxNeighbors = 4;
    const maxDistanceKm = 500.0;

    final connections = <VillageId, Set<VillageId>>{};
    for (final v in villages) {
      connections[v.id] = {};
    }

    // Sort villages by distance and connect nearest neighbors
    for (final village in villages) {
      final others = villages.where((v) => v.id != village.id).toList();
      others.sort((a, b) {
        final distA = village.coordinates.distanceToKm(a.coordinates);
        final distB = village.coordinates.distanceToKm(b.coordinates);
        return distA.compareTo(distB);
      });

      var added = 0;
      for (final other in others) {
        if (added >= maxNeighbors) break;
        final dist = village.coordinates.distanceToKm(other.coordinates);
        if (dist > maxDistanceKm) break;

        // Bidirectional connection
        connections[village.id]!.add(other.id);
        connections[other.id]!.add(village.id);
        added++;
      }
    }

    return connections;
  }

  void _assignStartingVillages() {
    // Update player village lists based on village ownership
    for (final player in state.players.values) {
      final ownedVillages = state.getPlayerVillages(player.id);
      state = state.updatePlayer(
        player.copyWith(villageIds: ownedVillages.map((v) => v.id).toList()),
      );
    }
  }
}
