import '../../../core/errors/failures.dart';
import '../../../core/types/result.dart';
import '../../../core/types/typed_ids.dart';
import '../../../domain/entities/army.dart';
import '../../../domain/entities/game_state.dart';
import '../../../domain/services/movement_service.dart';
import '../../state/game_state_notifier.dart';

/// Use case for sending an army to a destination.
class SendArmyUseCase {
  final GameStateNotifier _notifier;
  final MovementService _movementService;

  const SendArmyUseCase(this._notifier, this._movementService);

  /// Execute the army movement order.
  /// Returns the updated army on success.
  Result<Army> execute({
    required ArmyId armyId,
    required VillageId destinationId,
  }) {
    final state = _notifier.currentState;

    // Validate army exists
    final army = state.getArmy(armyId);
    if (army == null) {
      return Result.failure(ArmyNotFoundFailure(armyId));
    }

    // Check ownership
    if (army.owner != PlayerId.player) {
      return Result.failure(
        const NotOwnedByPlayerFailure('Cannot control armies you don\'t own'),
      );
    }

    // Use movement service to validate
    final validation = _movementService.validateMovement(
      state: state,
      army: army,
      destinationId: destinationId,
    );

    if (!validation.isValid) {
      return Result.failure(GenericInvalidMoveFailure(validation.errorMessage!));
    }

    // Execute movement
    _notifier.sendArmy(armyId, destinationId, validation.travelTime!);

    // Return updated army
    final updatedArmy = _notifier.currentState.getArmy(armyId)!;
    return Result.success(updatedArmy);
  }

  /// Execute for AI players (bypass ownership check).
  Result<Army> executeForAI({
    required ArmyId armyId,
    required VillageId destinationId,
    required PlayerId playerId,
  }) {
    final state = _notifier.currentState;

    // Validate army exists
    final army = state.getArmy(armyId);
    if (army == null) {
      return Result.failure(ArmyNotFoundFailure(armyId));
    }

    // Check ownership matches
    if (army.owner != playerId) {
      return Result.failure(
        const NotOwnedByPlayerFailure('Army not owned by this player'),
      );
    }

    // Use movement service to validate
    final validation = _movementService.validateMovement(
      state: state,
      army: army,
      destinationId: destinationId,
    );

    if (!validation.isValid) {
      return Result.failure(GenericInvalidMoveFailure(validation.errorMessage!));
    }

    // Execute movement
    _notifier.sendArmy(armyId, destinationId, validation.travelTime!);

    // Return updated army
    final updatedArmy = _notifier.currentState.getArmy(armyId)!;
    return Result.success(updatedArmy);
  }

  /// Get valid destinations for an army (for UI).
  List<DestinationInfo> getValidDestinations(GameState state, ArmyId armyId) {
    final army = state.getArmy(armyId);
    if (army == null) return [];

    final destinations = _movementService.getValidDestinations(
      state: state,
      army: army,
    );

    return destinations.map((village) {
      final origin = state.getVillage(army.stationedAt!);
      final travelTime = origin != null
          ? _movementService.calculateTravelTime(
              origin.coordinates,
              village.coordinates,
            )
          : 1;

      return DestinationInfo(
        villageId: village.id,
        villageName: village.name,
        travelTime: travelTime,
        isAttack: village.owner != army.owner,
        owner: village.owner,
      );
    }).toList();
  }

  /// Check if a specific movement is valid (for UI validation).
  MovementCheckResult canMove({
    required GameState state,
    required ArmyId armyId,
    required VillageId destinationId,
  }) {
    final army = state.getArmy(armyId);
    if (army == null) {
      return const MovementCheckResult(isValid: false, reason: 'Army not found');
    }

    final validation = _movementService.validateMovement(
      state: state,
      army: army,
      destinationId: destinationId,
    );

    if (!validation.isValid) {
      return MovementCheckResult(isValid: false, reason: validation.errorMessage);
    }

    final destination = state.getVillage(destinationId);
    return MovementCheckResult(
      isValid: true,
      travelTime: validation.travelTime,
      isAttack: destination?.owner != army.owner,
    );
  }
}

/// Information about a possible destination.
class DestinationInfo {
  final VillageId villageId;
  final String villageName;
  final int travelTime;
  final bool isAttack;
  final PlayerId owner;

  const DestinationInfo({
    required this.villageId,
    required this.villageName,
    required this.travelTime,
    required this.isAttack,
    required this.owner,
  });
}

/// Result of movement validation check.
class MovementCheckResult {
  final bool isValid;
  final String? reason;
  final int? travelTime;
  final bool? isAttack;

  const MovementCheckResult({
    required this.isValid,
    this.reason,
    this.travelTime,
    this.isAttack,
  });
}
