import '../../core/types/typed_ids.dart';
import '../entities/army.dart';
import '../entities/game_state.dart';
import '../entities/village.dart';
import '../value_objects/geo_coordinate.dart';

/// Result of movement validation.
class MovementValidation {
  final bool isValid;
  final String? errorMessage;
  final int? travelTime;

  const MovementValidation.valid(this.travelTime)
      : isValid = true,
        errorMessage = null;

  const MovementValidation.invalid(this.errorMessage)
      : isValid = false,
        travelTime = null;
}

/// Pure movement calculation service.
/// All methods compute results without side effects.
class MovementService {
  const MovementService();

  /// Validate if an army can move to a destination.
  MovementValidation validateMovement({
    required GameState state,
    required Army army,
    required VillageId destinationId,
  }) {
    // Check if army exists and is stationed
    if (army.stationedAt == null) {
      return const MovementValidation.invalid('Army is not stationed');
    }

    // Check if already marching
    if (army.isMarching) {
      return const MovementValidation.invalid('Army is already marching');
    }

    // Check if destination exists
    final destination = state.getVillage(destinationId);
    if (destination == null) {
      return const MovementValidation.invalid('Destination not found');
    }

    // Check if villages are connected
    if (!state.areNeighbors(army.stationedAt!, destinationId)) {
      return const MovementValidation.invalid('Destination not connected');
    }

    // Calculate travel time
    final origin = state.getVillage(army.stationedAt!);
    if (origin == null) {
      return const MovementValidation.invalid('Origin not found');
    }

    final travelTime = calculateTravelTime(
      origin.coordinates,
      destination.coordinates,
    );

    return MovementValidation.valid(travelTime);
  }

  /// Calculate travel time between two coordinates.
  int calculateTravelTime(GeoCoordinate from, GeoCoordinate to) {
    return from.travelTimeTo(to);
  }

  /// Get valid destinations for an army.
  List<Village> getValidDestinations({
    required GameState state,
    required Army army,
  }) {
    if (army.stationedAt == null || army.isMarching) {
      return [];
    }

    return state.getNeighbors(army.stationedAt!);
  }

  /// Check if movement would be an attack.
  bool isAttack({
    required GameState state,
    required Army army,
    required VillageId destinationId,
  }) {
    final destination = state.getVillage(destinationId);
    if (destination == null) return false;
    return destination.owner != army.owner;
  }

  /// Check if two marching armies will intercept.
  InterceptionResult? checkInterception({
    required GameState state,
    required Army army1,
    required Army army2,
  }) {
    // Both must be marching
    if (!army1.isMarching || !army2.isMarching) return null;

    // Must belong to different owners
    if (army1.owner == army2.owner) return null;

    // Check if they're heading towards each other
    if (army1.destination == army2.origin && army2.destination == army1.origin) {
      // They'll meet in the middle
      final turnsToMeet =
          (army1.turnsUntilArrival + army2.turnsUntilArrival) ~/ 2;
      if (turnsToMeet <= 1) {
        return InterceptionResult(
          army1: army1,
          army2: army2,
          locationId: army1.origin ?? army1.destination!,
        );
      }
    }

    // Check if one is heading to a location the other will pass through
    if (army1.destination == army2.stationedAt && army2.destination == army1.stationedAt) {
      // Crossing paths
      if (army1.turnsUntilArrival == army2.turnsUntilArrival) {
        return InterceptionResult(
          army1: army1,
          army2: army2,
          locationId: army1.destination!,
        );
      }
    }

    return null;
  }

  /// Calculate distance between two villages.
  double calculateDistance(Village from, Village to) {
    return from.coordinates.distanceToKm(to.coordinates);
  }

  /// Get armies that will arrive this turn.
  List<Army> getArrivingArmies(GameState state) {
    return state.armies.values
        .where((a) => a.isMarching && a.turnsUntilArrival == 1)
        .toList();
  }

  /// Get armies approaching a village.
  List<Army> getApproachingEnemies({
    required GameState state,
    required VillageId villageId,
    required PlayerId defenderId,
  }) {
    return state.armies.values
        .where((a) =>
            a.destination == villageId &&
            a.owner != defenderId &&
            a.isMarching)
        .toList();
  }
}

/// Result of interception check.
class InterceptionResult {
  final Army army1;
  final Army army2;
  final VillageId locationId;

  const InterceptionResult({
    required this.army1,
    required this.army2,
    required this.locationId,
  });
}
