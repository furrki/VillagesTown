import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/types/typed_ids.dart';
import '../value_objects/resources.dart';
import 'army.dart';
import 'player.dart';
import 'village.dart';

part 'game_state.freezed.dart';
// Note: GameState serialization handled by DTOs in infrastructure layer

/// Battle record for tracking combat history.
@freezed
class BattleRound with _$BattleRound {
  const factory BattleRound({
    required List<int> attackerRolls,
    required List<int> defenderRolls,
    @Default(0) int attackerBonus,
    @Default(0) int defenderBonus,
    required int attackerLosses,
    required int defenderLosses,
    @Default('') String narration,
  }) = _BattleRound;
}

/// Record of a battle for display/history.
@freezed
class BattleRecord with _$BattleRecord {
  const BattleRecord._();

  const factory BattleRecord({
    required BattleId id,
    required String attackerName,
    required String defenderName,
    required PlayerId attackerId,
    required PlayerId defenderId,
    VillageId? originVillageId,
    required String locationName,
    required List<BattleRound> rounds,
    required bool attackerWon,
    required int initialAttackerCount,
    required int initialDefenderCount,
    @Default(0) int initialGarrisonCount,
    required DateTime timestamp,
    @Default(true) bool isPending,
  }) = _BattleRecord;


  int get totalAttackerLosses =>
      rounds.fold(0, (sum, r) => sum + r.attackerLosses);

  int get totalDefenderLosses =>
      rounds.fold(0, (sum, r) => sum + r.defenderLosses);

  int get roundCount => rounds.length;
}

/// Turn event types for the event log.
sealed class TurnEvent {
  String get emoji;
  String get message;
  bool get isImportant;
}

class ResourceGainEvent extends TurnEvent {
  final VillageId villageId;
  final ResourceBundle gained;

  ResourceGainEvent(this.villageId, this.gained);

  @override
  String get emoji => '📦';
  @override
  String get message => 'Resources gained';
  @override
  bool get isImportant => false;
}

class ArmySentEvent extends TurnEvent {
  final ArmyId armyId;
  final VillageId from;
  final VillageId to;

  ArmySentEvent(this.armyId, this.from, this.to);

  @override
  String get emoji => '🚶';
  @override
  String get message => 'Army dispatched';
  @override
  bool get isImportant => false;
}

class ArmyArrivedEvent extends TurnEvent {
  final ArmyId armyId;
  final VillageId destination;

  ArmyArrivedEvent(this.armyId, this.destination);

  @override
  String get emoji => '🏁';
  @override
  String get message => 'Army arrived';
  @override
  bool get isImportant => false;
}

class BattleWonEvent extends TurnEvent {
  final BattleId battleId;
  final String locationName;

  BattleWonEvent(this.battleId, this.locationName);

  @override
  String get emoji => '⚔️';
  @override
  String get message => 'Victory at $locationName!';
  @override
  bool get isImportant => true;
}

class BattleLostEvent extends TurnEvent {
  final BattleId battleId;
  final String locationName;

  BattleLostEvent(this.battleId, this.locationName);

  @override
  String get emoji => '💀';
  @override
  String get message => 'Defeat at $locationName';
  @override
  bool get isImportant => true;
}

class VillageConqueredEvent extends TurnEvent {
  final VillageId villageId;
  final String villageName;

  VillageConqueredEvent(this.villageId, this.villageName);

  @override
  String get emoji => '🎉';
  @override
  String get message => 'Conquered $villageName!';
  @override
  bool get isImportant => true;
}

class VillageLostEvent extends TurnEvent {
  final VillageId villageId;
  final String villageName;

  VillageLostEvent(this.villageId, this.villageName);

  @override
  String get emoji => '😢';
  @override
  String get message => 'Lost $villageName';
  @override
  bool get isImportant => true;
}

class EnemyApproachingEvent extends TurnEvent {
  final VillageId targetVillageId;
  final String targetName;
  final int turnsAway;

  EnemyApproachingEvent(this.targetVillageId, this.targetName, this.turnsAway);

  @override
  String get emoji => '⚠️';
  @override
  String get message => 'Enemy approaching $targetName ($turnsAway turns)';
  @override
  bool get isImportant => true;
}

class GeneralEvent extends TurnEvent {
  final String _message;
  final bool _important;

  GeneralEvent(this._message, {bool important = false}) : _important = important;

  @override
  String get emoji => 'ℹ️';
  @override
  String get message => _message;
  @override
  bool get isImportant => _important;
}

/// Aggregate root containing all game state.
@freezed
class GameState with _$GameState {
  const GameState._();

  const factory GameState({
    required Map<VillageId, Village> villages,
    required Map<ArmyId, Army> armies,
    required Map<PlayerId, Player> players,
    required Map<VillageId, Set<VillageId>> connections,
    @Default(0) int currentTurn,
    @Default(PlayerId.player) PlayerId currentPlayerId,
    @Default(false) bool gameStarted,
    @Default({}) Map<PlayerId, ResourceBundle> globalResources,
    @Default({}) Set<VillageId> discoveredVillages,
    @Default([]) List<BattleRecord> pendingBattles,
    @Default(null) PlayerId? winnerId,
  }) = _GameState;

  /// Initial empty game state.
  factory GameState.initial() => const GameState(
        villages: {},
        armies: {},
        players: {},
        connections: {},
      );

  // === Queries ===

  Village? getVillage(VillageId id) => villages[id];
  Army? getArmy(ArmyId id) => armies[id];
  Player? getPlayer(PlayerId id) => players[id];

  Player? get currentPlayer => players[currentPlayerId];
  Player? get humanPlayer => players[PlayerId.player];
  Player? get winner => winnerId != null ? players[winnerId] : null;

  List<Village> getPlayerVillages(PlayerId playerId) =>
      villages.values.where((v) => v.owner == playerId).toList();

  List<Army> getPlayerArmies(PlayerId playerId) =>
      armies.values.where((a) => a.owner == playerId).toList();

  List<Army> getArmiesAt(VillageId villageId) =>
      armies.values.where((a) => a.stationedAt == villageId).toList();

  List<Army> getMarchingArmies(PlayerId playerId) =>
      armies.values.where((a) => a.owner == playerId && a.isMarching).toList();

  List<Village> getNeighbors(VillageId villageId) {
    final neighborIds = connections[villageId] ?? {};
    return neighborIds.map((id) => villages[id]).whereType<Village>().toList();
  }

  bool areNeighbors(VillageId a, VillageId b) =>
      connections[a]?.contains(b) ?? false;

  List<Player> get activePlayers =>
      players.values.where((p) => !p.isEliminated && !p.isNeutral).toList();

  List<Player> get aiPlayers =>
      players.values.where((p) => p.isAI && !p.isEliminated && !p.isNeutral).toList();

  ResourceBundle getGlobalResources(PlayerId playerId) =>
      globalResources[playerId] ?? ResourceBundle.empty;

  bool hasPendingBattles(PlayerId playerId) =>
      pendingBattles.any((b) => b.attackerId == playerId || b.defenderId == playerId);

  List<BattleRecord> getPendingBattlesFor(PlayerId playerId) =>
      pendingBattles.where((b) =>
          b.isPending && (b.attackerId == playerId || b.defenderId == playerId)).toList();

  bool get isGameOver => winnerId != null || activePlayers.length <= 1;

  // === State modifications (return new state) ===

  GameState updateVillage(Village village) => copyWith(
        villages: {...villages, village.id: village},
      );

  GameState updateArmy(Army army) => copyWith(
        armies: {...armies, army.id: army},
      );

  GameState removeArmy(ArmyId armyId) {
    final newArmies = Map<ArmyId, Army>.from(armies)..remove(armyId);
    return copyWith(armies: newArmies);
  }

  GameState addArmy(Army army) => copyWith(
        armies: {...armies, army.id: army},
      );

  GameState updatePlayer(Player player) => copyWith(
        players: {...players, player.id: player},
      );

  GameState setGlobalResources(PlayerId playerId, ResourceBundle resources) =>
      copyWith(
        globalResources: {...globalResources, playerId: resources},
      );

  GameState addPendingBattle(BattleRecord battle) => copyWith(
        pendingBattles: [...pendingBattles, battle],
      );

  GameState removePendingBattle(BattleId battleId) => copyWith(
        pendingBattles: pendingBattles.where((b) => b.id != battleId).toList(),
      );

  GameState discoverVillage(VillageId villageId) => copyWith(
        discoveredVillages: {...discoveredVillages, villageId},
      );

  GameState incrementTurn() => copyWith(currentTurn: currentTurn + 1);

  GameState setWinner(PlayerId playerId) => copyWith(winnerId: playerId);

  GameState startGame() => copyWith(gameStarted: true);
}
