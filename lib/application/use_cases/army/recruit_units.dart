import '../../../core/errors/failures.dart';
import '../../../core/types/result.dart';
import '../../../core/types/typed_ids.dart';
import '../../../domain/entities/army.dart';
import '../../../domain/entities/building.dart';
import '../../../domain/entities/game_state.dart';
import '../../../domain/entities/unit.dart';
import '../../state/game_state_notifier.dart';

/// Use case for recruiting units into an army.
class RecruitUnitsUseCase {
  final GameStateNotifier _notifier;

  const RecruitUnitsUseCase(this._notifier);

  /// Recruit units at a village.
  /// If no army exists at the village, creates one.
  /// Returns the updated/created army on success.
  Result<Army> execute({
    required VillageId villageId,
    required UnitType unitType,
    required int count,
    PlayerId? owner,
  }) {
    final state = _notifier.currentState;
    final playerId = owner ?? PlayerId.player;

    // Validate village exists
    final village = state.getVillage(villageId);
    if (village == null) {
      return Result.failure(VillageNotFoundFailure(villageId));
    }

    // Check ownership
    if (village.owner != playerId) {
      return Result.failure(
        const NotOwnedByPlayerFailure('Cannot recruit in villages you don\'t own'),
      );
    }

    // Check recruitment limit
    final recruitLimit = village.maxRecruitsPerTurn;
    if (count > recruitLimit) {
      return Result.failure(
        RecruitmentLimitFailure(requested: count, available: recruitLimit),
      );
    }

    // Calculate total cost
    final unitCost = unitType.cost;
    final totalCost = unitCost * count;

    // Check resources
    final playerResources = state.getGlobalResources(playerId);
    if (!playerResources.canAfford(totalCost)) {
      return Result.failure(
        InsufficientResourcesFailure.fromBundles(
          requiredResources: totalCost,
          availableResources: playerResources,
        ),
      );
    }

    // Deduct resources
    _notifier.modifyResources(playerId, -totalCost);

    // Create units
    final units = List.generate(count, (_) => Unit.create(unitType, playerId));

    // Find or create army at village
    final existingArmies = state.getArmiesAt(villageId)
        .where((a) => a.owner == playerId && !a.isMarching)
        .toList();

    Army resultArmy;
    if (existingArmies.isNotEmpty) {
      // Add to existing army
      final army = existingArmies.first;
      _notifier.addUnitsToArmy(army.id, units);
      resultArmy = _notifier.currentState.getArmy(army.id)!;
    } else {
      // Create new army
      _notifier.createArmy(
        units: units,
        owner: playerId,
        stationedAt: villageId,
      );
      // Get the newly created army (it's the last one added)
      resultArmy = _notifier.currentState.armies.values
          .where((a) => a.owner == playerId && a.stationedAt == villageId)
          .last;
    }

    return Result.success(resultArmy);
  }

  /// Check if units can be recruited (for UI validation).
  RecruitmentValidation canRecruit({
    required GameState state,
    required VillageId villageId,
    required UnitType unitType,
    required int count,
    PlayerId? owner,
  }) {
    final playerId = owner ?? PlayerId.player;
    final village = state.getVillage(villageId);

    if (village == null) {
      return const RecruitmentValidation(
        isValid: false,
        reason: 'Village not found',
        maxAffordable: 0,
      );
    }

    if (village.owner != playerId) {
      return const RecruitmentValidation(
        isValid: false,
        reason: 'Not your village',
        maxAffordable: 0,
      );
    }

    final recruitLimit = village.maxRecruitsPerTurn;
    final playerResources = state.getGlobalResources(playerId);
    final unitCost = unitType.cost;

    // Calculate max affordable
    final maxByGold = unitCost.gold > 0 ? playerResources.gold ~/ unitCost.gold : 999;
    final maxByFood = unitCost.food > 0 ? playerResources.food ~/ unitCost.food : 999;
    final maxByWood = unitCost.wood > 0 ? playerResources.wood ~/ unitCost.wood : 999;
    final maxByIron = unitCost.iron > 0 ? playerResources.iron ~/ unitCost.iron : 999;
    final maxAffordable = [maxByGold, maxByFood, maxByWood, maxByIron, recruitLimit]
        .reduce((a, b) => a < b ? a : b);

    if (count > recruitLimit) {
      return RecruitmentValidation(
        isValid: false,
        reason: 'Exceeds recruitment limit ($recruitLimit)',
        maxAffordable: maxAffordable,
      );
    }

    final totalCost = unitCost * count;
    if (!playerResources.canAfford(totalCost)) {
      return RecruitmentValidation(
        isValid: false,
        reason: 'Insufficient resources',
        maxAffordable: maxAffordable,
      );
    }

    return RecruitmentValidation(
      isValid: true,
      maxAffordable: maxAffordable,
    );
  }

  /// Get available unit types for recruitment at a village.
  List<UnitType> getAvailableUnitTypes(GameState state, VillageId villageId) {
    final village = state.getVillage(villageId);
    if (village == null) return [];

    return UnitType.values.where((type) {
      // Check building requirements
      switch (type) {
        case UnitType.militia:
          return true; // Always available
        case UnitType.spearman:
        case UnitType.swordsman:
          return village.hasBuilding(BuildingType.barracks);
        case UnitType.archer:
        case UnitType.crossbowman:
          return village.hasBuilding(BuildingType.archeryRange);
        case UnitType.lightCavalry:
        case UnitType.knight:
          return village.hasBuilding(BuildingType.stables);
      }
    }).toList();
  }
}

/// Result of recruitment validation.
class RecruitmentValidation {
  final bool isValid;
  final String? reason;
  final int maxAffordable;

  const RecruitmentValidation({
    required this.isValid,
    this.reason,
    required this.maxAffordable,
  });
}
