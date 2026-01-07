import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/types/typed_ids.dart';
import '../../domain/entities/army.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/entities/nationality.dart';
import '../../domain/entities/player.dart';
import '../../domain/entities/village.dart';
import '../../domain/value_objects/resources.dart';
import 'game_state_notifier.dart';

// =============================================================================
// CORE STATE PROVIDER
// =============================================================================

/// The main game state provider.
/// All game state flows through this single source of truth.
final gameStateProvider =
    StateNotifierProvider<GameStateNotifier, GameState>((ref) {
  return GameStateNotifier();
});

// =============================================================================
// GAME STATUS PROVIDERS
// =============================================================================

/// Whether the game has started.
final gameStartedProvider = Provider<bool>((ref) {
  return ref.watch(gameStateProvider.select((s) => s.gameStarted));
});

/// Current turn number.
final currentTurnProvider = Provider<int>((ref) {
  return ref.watch(gameStateProvider.select((s) => s.currentTurn));
});

/// Current player ID.
final currentPlayerIdProvider = Provider<PlayerId>((ref) {
  return ref.watch(gameStateProvider.select((s) => s.currentPlayerId));
});

/// Whether the game is over.
final isGameOverProvider = Provider<bool>((ref) {
  return ref.watch(gameStateProvider.select((s) => s.isGameOver));
});

/// Winner of the game (null if game not over).
final winnerProvider = Provider<Player?>((ref) {
  return ref.watch(gameStateProvider.select((s) => s.winner));
});

// =============================================================================
// PLAYER PROVIDERS
// =============================================================================

/// Get a specific player by ID.
final playerProvider = Provider.family<Player?, PlayerId>((ref, playerId) {
  return ref.watch(gameStateProvider.select((s) => s.getPlayer(playerId)));
});

/// The human player.
final humanPlayerProvider = Provider<Player?>((ref) {
  return ref.watch(playerProvider(PlayerId.player));
});

/// All active (non-eliminated) players.
final activePlayersProvider = Provider<List<Player>>((ref) {
  return ref.watch(gameStateProvider.select((s) => s.activePlayers));
});

/// All AI players.
final aiPlayersProvider = Provider<List<Player>>((ref) {
  return ref.watch(gameStateProvider.select((s) => s.aiPlayers));
});

// =============================================================================
// VILLAGE PROVIDERS
// =============================================================================

/// Get a specific village by ID.
final villageProvider = Provider.family<Village?, VillageId>((ref, villageId) {
  return ref.watch(gameStateProvider.select((s) => s.getVillage(villageId)));
});

/// All villages owned by a player.
final playerVillagesProvider =
    Provider.family<List<Village>, PlayerId>((ref, playerId) {
  return ref.watch(gameStateProvider.select((s) => s.getPlayerVillages(playerId)));
});

/// Human player's villages.
final humanVillagesProvider = Provider<List<Village>>((ref) {
  return ref.watch(playerVillagesProvider(PlayerId.player));
});

/// All villages in the game.
final allVillagesProvider = Provider<List<Village>>((ref) {
  return ref.watch(gameStateProvider.select((s) => s.villages.values.toList()));
});

/// Neighbors of a village.
final villageNeighborsProvider =
    Provider.family<List<Village>, VillageId>((ref, villageId) {
  return ref.watch(gameStateProvider.select((s) => s.getNeighbors(villageId)));
});

/// Discovered villages (for fog of war).
final discoveredVillagesProvider = Provider<Set<VillageId>>((ref) {
  return ref.watch(gameStateProvider.select((s) => s.discoveredVillages));
});

// =============================================================================
// ARMY PROVIDERS
// =============================================================================

/// Get a specific army by ID.
final armyProvider = Provider.family<Army?, ArmyId>((ref, armyId) {
  return ref.watch(gameStateProvider.select((s) => s.getArmy(armyId)));
});

/// All armies owned by a player.
final playerArmiesProvider =
    Provider.family<List<Army>, PlayerId>((ref, playerId) {
  return ref.watch(gameStateProvider.select((s) => s.getPlayerArmies(playerId)));
});

/// Human player's armies.
final humanArmiesProvider = Provider<List<Army>>((ref) {
  return ref.watch(playerArmiesProvider(PlayerId.player));
});

/// Armies stationed at a village.
final armiesAtVillageProvider =
    Provider.family<List<Army>, VillageId>((ref, villageId) {
  return ref.watch(gameStateProvider.select((s) => s.getArmiesAt(villageId)));
});

/// Marching armies for a player.
final marchingArmiesProvider =
    Provider.family<List<Army>, PlayerId>((ref, playerId) {
  return ref.watch(gameStateProvider.select((s) => s.getMarchingArmies(playerId)));
});

/// All armies in the game.
final allArmiesProvider = Provider<List<Army>>((ref) {
  return ref.watch(gameStateProvider.select((s) => s.armies.values.toList()));
});

// =============================================================================
// RESOURCE PROVIDERS
// =============================================================================

/// Global resources for a player.
final globalResourcesProvider =
    Provider.family<ResourceBundle, PlayerId>((ref, playerId) {
  return ref.watch(gameStateProvider.select((s) => s.getGlobalResources(playerId)));
});

/// Human player's resources.
final humanResourcesProvider = Provider<ResourceBundle>((ref) {
  return ref.watch(globalResourcesProvider(PlayerId.player));
});

// =============================================================================
// BATTLE PROVIDERS
// =============================================================================

/// All pending battles.
final pendingBattlesProvider = Provider<List<BattleRecord>>((ref) {
  return ref.watch(gameStateProvider.select((s) => s.pendingBattles));
});

/// Pending battles for a specific player.
final playerPendingBattlesProvider =
    Provider.family<List<BattleRecord>, PlayerId>((ref, playerId) {
  return ref
      .watch(gameStateProvider.select((s) => s.getPendingBattlesFor(playerId)));
});

/// Whether player has pending battles.
final hasPendingBattlesProvider =
    Provider.family<bool, PlayerId>((ref, playerId) {
  return ref
      .watch(gameStateProvider.select((s) => s.hasPendingBattles(playerId)));
});

// =============================================================================
// UI STATE PROVIDERS (Selection, etc.)
// =============================================================================

/// Currently selected village.
final selectedVillageIdProvider = StateProvider<VillageId?>((ref) => null);

/// Currently selected village entity.
final selectedVillageProvider = Provider<Village?>((ref) {
  final id = ref.watch(selectedVillageIdProvider);
  if (id == null) return null;
  return ref.watch(villageProvider(id));
});

/// Currently selected army.
final selectedArmyIdProvider = StateProvider<ArmyId?>((ref) => null);

/// Currently selected army entity.
final selectedArmyProvider = Provider<Army?>((ref) {
  final id = ref.watch(selectedArmyIdProvider);
  if (id == null) return null;
  return ref.watch(armyProvider(id));
});

/// Whether turn processing is in progress.
final isProcessingTurnProvider = StateProvider<bool>((ref) => false);

// =============================================================================
// NATIONALITY PROVIDERS
// =============================================================================

/// Get nationality by ID.
final nationalityProvider =
    Provider.family<Nationality?, NationalityId>((ref, nationalityId) {
  return Nationality.byId(nationalityId);
});

/// All nationalities.
final allNationalitiesProvider = Provider<List<Nationality>>((ref) {
  return Nationality.all;
});

/// Major nationalities only.
final majorNationalitiesProvider = Provider<List<Nationality>>((ref) {
  return Nationality.major;
});
