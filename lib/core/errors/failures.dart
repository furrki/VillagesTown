import '../types/typed_ids.dart';
import '../../domain/value_objects/resources.dart';

/// Base class for all domain failures.
/// Failures are expected errors that can be handled gracefully.
sealed class Failure implements Exception {
  final String message;

  const Failure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

// === Entity Not Found Failures ===

class VillageNotFoundFailure extends Failure {
  final VillageId villageId;

  VillageNotFoundFailure(this.villageId)
      : super('Village not found: ${villageId.value}');
}

class ArmyNotFoundFailure extends Failure {
  final ArmyId armyId;

  ArmyNotFoundFailure(this.armyId) : super('Army not found: ${armyId.value}');
}

class PlayerNotFoundFailure extends Failure {
  final PlayerId playerId;

  PlayerNotFoundFailure(this.playerId)
      : super('Player not found: ${playerId.value}');
}

class UnitNotFoundFailure extends Failure {
  final UnitId unitId;

  UnitNotFoundFailure(this.unitId) : super('Unit not found: ${unitId.value}');
}

// === Movement Failures ===

class ArmyNotStationedFailure extends Failure {
  final ArmyId armyId;

  ArmyNotStationedFailure(this.armyId)
      : super('Army is not stationed at any village: ${armyId.value}');
}

class InvalidMoveFailure extends Failure {
  final VillageId from;
  final VillageId to;

  InvalidMoveFailure(this.from, this.to)
      : super(
            'Cannot move from ${from.value} to ${to.value} - not connected');
}

class ArmyAlreadyMarchingFailure extends Failure {
  final ArmyId armyId;

  ArmyAlreadyMarchingFailure(this.armyId)
      : super('Army is already marching: ${armyId.value}');
}

// === Resource Failures ===

class InsufficientResourcesFailure extends Failure {
  final String resourceType;
  final int required;
  final int available;

  InsufficientResourcesFailure({
    required this.resourceType,
    required this.required,
    required this.available,
  }) : super(
            'Insufficient $resourceType: need $required, have $available');

  /// Create from ResourceBundles for convenience.
  factory InsufficientResourcesFailure.fromBundles({
    required ResourceBundle requiredResources,
    required ResourceBundle availableResources,
  }) {
    // Find the first resource type that's insufficient
    final types = ['gold', 'food', 'wood', 'iron'];
    final reqValues = [requiredResources.gold, requiredResources.food, requiredResources.wood, requiredResources.iron];
    final availValues = [availableResources.gold, availableResources.food, availableResources.wood, availableResources.iron];

    for (var i = 0; i < types.length; i++) {
      if (reqValues[i] > availValues[i]) {
        return InsufficientResourcesFailure(
          resourceType: types[i],
          required: reqValues[i],
          available: availValues[i],
        );
      }
    }

    return InsufficientResourcesFailure(
      resourceType: 'resources',
      required: requiredResources.total,
      available: availableResources.total,
    );
  }
}

class InsufficientFundsFailure extends Failure {
  final double required;
  final double available;

  InsufficientFundsFailure({
    required this.required,
    required this.available,
  }) : super('Insufficient funds: need $required, have $available');
}

// === Building Failures ===

class BuildingCapReachedFailure extends Failure {
  final VillageId villageId;
  final int maxBuildings;

  BuildingCapReachedFailure(this.villageId, this.maxBuildings)
      : super(
            'Village ${villageId.value} has reached max buildings: $maxBuildings');
}

class BuildingAlreadyExistsFailure extends Failure {
  final VillageId villageId;
  final String buildingType;

  BuildingAlreadyExistsFailure(this.villageId, this.buildingType)
      : super(
            'Village ${villageId.value} already has a $buildingType');
}

class MissingRequiredBuildingFailure extends Failure {
  final String requiredBuilding;
  final String action;

  MissingRequiredBuildingFailure(this.requiredBuilding, this.action)
      : super('$requiredBuilding required to $action');
}

// === Recruitment Failures ===

class InsufficientPopulationFailure extends Failure {
  final VillageId villageId;
  final int required;
  final int available;

  InsufficientPopulationFailure({
    required this.villageId,
    required this.required,
    required this.available,
  }) : super(
            'Insufficient population in ${villageId.value}: need $required, have $available');
}

class RecruitmentCapReachedFailure extends Failure {
  final VillageId villageId;
  final int maxRecruits;

  RecruitmentCapReachedFailure(this.villageId, this.maxRecruits)
      : super(
            'Village ${villageId.value} has reached max recruits this turn: $maxRecruits');
}

// === Combat Failures ===

class InvalidCombatFailure extends Failure {
  const InvalidCombatFailure(super.message);
}

class BattleNotFoundFailure extends Failure {
  final BattleId battleId;

  BattleNotFoundFailure(this.battleId)
      : super('Battle not found: ${battleId.value}');
}

// === Persistence Failures ===

class NoSaveFoundFailure extends Failure {
  const NoSaveFoundFailure() : super('No saved game found');
}

class SerializationFailure extends Failure {
  const SerializationFailure(String details)
      : super('Failed to serialize game state: $details');
}

class DeserializationFailure extends Failure {
  const DeserializationFailure(String details)
      : super('Failed to deserialize game state: $details');
}

class StorageFailure extends Failure {
  const StorageFailure(String details)
      : super('Storage operation failed: $details');
}

// === Ownership Failures ===

class NotOwnedByPlayerFailure extends Failure {
  const NotOwnedByPlayerFailure(super.message);
}

// === General Failures ===

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class GenericInvalidMoveFailure extends Failure {
  const GenericInvalidMoveFailure(super.message);
}

class AlreadyExistsFailure extends Failure {
  const AlreadyExistsFailure(super.message);
}

class BuildingLimitReachedFailure extends Failure {
  const BuildingLimitReachedFailure(super.message);
}

class RecruitmentLimitFailure extends Failure {
  final int requested;
  final int available;

  RecruitmentLimitFailure({required this.requested, required this.available})
      : super('Recruitment limit exceeded: requested $requested, max available $available');
}

class UnexpectedFailure extends Failure {
  final Object? error;

  UnexpectedFailure(this.error)
      : super('Unexpected error: ${error?.toString() ?? 'unknown'}');
}
