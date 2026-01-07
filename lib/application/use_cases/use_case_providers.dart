import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/combat_service.dart';
import '../../domain/services/movement_service.dart';
import '../../domain/services/production_service.dart';
import '../state/providers.dart';
import 'army/recruit_units.dart';
import 'army/send_army.dart';
import 'building/construct_building.dart';
import 'combat/resolve_combat.dart';
import 'turn/process_turn.dart';

// =============================================================================
// SERVICE PROVIDERS
// =============================================================================

/// Combat service provider.
final combatServiceProvider = Provider<CombatService>((ref) {
  return CombatService();
});

/// Movement service provider.
final movementServiceProvider = Provider<MovementService>((ref) {
  return const MovementService();
});

/// Production service provider.
final productionServiceProvider = Provider<ProductionService>((ref) {
  return const ProductionService();
});

// =============================================================================
// USE CASE PROVIDERS
// =============================================================================

/// Construct building use case.
final constructBuildingUseCaseProvider = Provider<ConstructBuildingUseCase>((ref) {
  final notifier = ref.watch(gameStateProvider.notifier);
  return ConstructBuildingUseCase(notifier);
});

/// Recruit units use case.
final recruitUnitsUseCaseProvider = Provider<RecruitUnitsUseCase>((ref) {
  final notifier = ref.watch(gameStateProvider.notifier);
  return RecruitUnitsUseCase(notifier);
});

/// Send army use case.
final sendArmyUseCaseProvider = Provider<SendArmyUseCase>((ref) {
  final notifier = ref.watch(gameStateProvider.notifier);
  final movementService = ref.watch(movementServiceProvider);
  return SendArmyUseCase(notifier, movementService);
});

/// Resolve combat use case.
final resolveCombatUseCaseProvider = Provider<ResolveCombatUseCase>((ref) {
  final notifier = ref.watch(gameStateProvider.notifier);
  final combatService = ref.watch(combatServiceProvider);
  return ResolveCombatUseCase(notifier, combatService);
});

/// Process turn use case.
final processTurnUseCaseProvider = Provider<ProcessTurnUseCase>((ref) {
  final notifier = ref.watch(gameStateProvider.notifier);
  final combatService = ref.watch(combatServiceProvider);
  final movementService = ref.watch(movementServiceProvider);
  final productionService = ref.watch(productionServiceProvider);
  return ProcessTurnUseCase(
    notifier,
    combatService,
    movementService,
    productionService,
  );
});

// =============================================================================
// CONVENIENCE PROVIDERS
// =============================================================================

/// Process turn and return result.
/// Usage: ref.read(processTurnProvider)
final processTurnProvider = Provider<TurnResult Function()>((ref) {
  final useCase = ref.watch(processTurnUseCaseProvider);
  return useCase.execute;
});
