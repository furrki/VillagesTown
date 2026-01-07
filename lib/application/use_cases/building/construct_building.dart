import '../../../core/errors/failures.dart';
import '../../../core/types/result.dart';
import '../../../core/types/typed_ids.dart';
import '../../../domain/entities/building.dart';
import '../../../domain/entities/game_state.dart';
import '../../../domain/entities/village.dart';
import '../../state/game_state_notifier.dart';

/// Use case for constructing a building in a village.
class ConstructBuildingUseCase {
  final GameStateNotifier _notifier;

  const ConstructBuildingUseCase(this._notifier);

  /// Execute the building construction.
  /// Returns the updated village on success.
  Result<Village> execute({
    required VillageId villageId,
    required BuildingType buildingType,
  }) {
    final state = _notifier.currentState;

    // Validate village exists
    final village = state.getVillage(villageId);
    if (village == null) {
      return Result.failure(VillageNotFoundFailure(villageId));
    }

    // Check ownership
    if (village.owner != PlayerId.player) {
      return Result.failure(
        const NotOwnedByPlayerFailure('Cannot build in villages you don\'t own'),
      );
    }

    // Check building slot limit
    if (!village.canBuildMore) {
      return Result.failure(
        const BuildingLimitReachedFailure('Village has reached maximum buildings'),
      );
    }

    // Check if already has this unique building
    if (buildingType.isUnique && village.hasBuilding(buildingType)) {
      return Result.failure(
        AlreadyExistsFailure('Village already has a ${buildingType.name}'),
      );
    }

    // Check resources
    final cost = buildingType.baseCost;
    final playerResources = state.getGlobalResources(PlayerId.player);
    if (!playerResources.canAfford(cost)) {
      return Result.failure(
        InsufficientResourcesFailure.fromBundles(
          requiredResources: cost,
          availableResources: playerResources,
        ),
      );
    }

    // Deduct resources
    _notifier.modifyResources(PlayerId.player, -cost);

    // Add building
    _notifier.addBuildingToVillage(villageId, buildingType);

    // Return updated village
    final updatedVillage = _notifier.currentState.getVillage(villageId)!;
    return Result.success(updatedVillage);
  }

  /// Check if a building can be constructed (for UI validation).
  ValidationResult canConstruct({
    required GameState state,
    required VillageId villageId,
    required BuildingType buildingType,
  }) {
    final village = state.getVillage(villageId);
    if (village == null) {
      return const ValidationResult(isValid: false, reason: 'Village not found');
    }

    if (village.owner != PlayerId.player) {
      return const ValidationResult(isValid: false, reason: 'Not your village');
    }

    if (!village.canBuildMore) {
      return const ValidationResult(isValid: false, reason: 'No building slots');
    }

    if (buildingType.isUnique && village.hasBuilding(buildingType)) {
      return ValidationResult(isValid: false, reason: 'Already has ${buildingType.name}');
    }

    final cost = buildingType.baseCost;
    final playerResources = state.getGlobalResources(PlayerId.player);
    if (!playerResources.canAfford(cost)) {
      return const ValidationResult(isValid: false, reason: 'Insufficient resources');
    }

    return const ValidationResult(isValid: true);
  }

  /// Get available buildings for a village.
  List<BuildingType> getAvailableBuildings(GameState state, VillageId villageId) {
    final village = state.getVillage(villageId);
    if (village == null || !village.canBuildMore) return [];

    return BuildingType.values.where((type) {
      // Skip if unique and already built
      if (type.isUnique && village.hasBuilding(type)) return false;
      return true;
    }).toList();
  }
}

/// Result of validation check.
class ValidationResult {
  final bool isValid;
  final String? reason;

  const ValidationResult({required this.isValid, this.reason});
}
