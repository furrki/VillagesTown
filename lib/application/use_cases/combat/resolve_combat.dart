import '../../../core/errors/failures.dart';
import '../../../core/types/result.dart';
import '../../../core/types/typed_ids.dart';
import '../../../domain/entities/army.dart';
import '../../../domain/entities/building.dart';
import '../../../domain/entities/game_state.dart';
import '../../../domain/entities/village.dart';
import '../../../domain/services/combat_service.dart';
import '../../state/game_state_notifier.dart';

/// Use case for resolving combat when an army arrives at a hostile village.
class ResolveCombatUseCase {
  final GameStateNotifier _notifier;
  final CombatService _combatService;

  const ResolveCombatUseCase(this._notifier, this._combatService);

  /// Resolve combat between an attacking army and village defenders.
  /// Returns the battle record with results.
  Result<BattleRecord> execute({
    required ArmyId attackingArmyId,
    required VillageId villageId,
  }) {
    final state = _notifier.currentState;

    // Validate attacker exists
    final attacker = state.getArmy(attackingArmyId);
    if (attacker == null) {
      return Result.failure(ArmyNotFoundFailure(attackingArmyId));
    }

    // Validate village exists
    final village = state.getVillage(villageId);
    if (village == null) {
      return Result.failure(VillageNotFoundFailure(villageId));
    }

    // Ensure this is actually an attack (different owners)
    if (village.owner == attacker.owner) {
      return Result.failure(
        const GenericInvalidMoveFailure('Cannot attack own village'),
      );
    }

    // Get defending armies at the village
    final defenders = state.getArmiesAt(villageId)
        .where((a) => a.owner == village.owner)
        .toList();

    // Collect all defender units
    final defenderUnits = defenders.expand((a) => a.units).toList();

    // Resolve combat using service
    final result = _combatService.resolveCombat(
      attackers: attacker.units,
      defenders: defenderUnits,
      garrisonStrength: village.garrisonStrength,
      defenderHasBonus: village.hasBuilding(BuildingType.fortress),
    );

    // Create battle record
    final battleRecord = _combatService.createBattleRecord(
      attacker: attacker,
      location: village,
      defenders: defenders,
      result: result,
    );

    // Add pending battle for UI display
    _notifier.addPendingBattle(battleRecord);

    // Apply combat results to state
    _applyCombatResults(
      attacker: attacker,
      defenders: defenders,
      village: village,
      result: result,
    );

    return Result.success(battleRecord);
  }

  /// Apply combat results to game state.
  void _applyCombatResults({
    required Army attacker,
    required List<Army> defenders,
    required Village village,
    required CombatResult result,
  }) {
    if (result.attackerWon) {
      // Attacker wins - capture village
      _handleAttackerVictory(attacker, defenders, village, result);
    } else {
      // Defender wins - attacker destroyed
      _handleDefenderVictory(attacker, defenders, village, result);
    }
  }

  void _handleAttackerVictory(
    Army attacker,
    List<Army> defenders,
    Village village,
    CombatResult result,
  ) {
    // Remove attacker casualties
    final survivingUnits = attacker.units.take(result.finalAttackerCount).toList();

    if (survivingUnits.isEmpty) {
      // All attackers died but still won (garrison destroyed)
      _notifier.removeArmy(attacker.id);
    } else {
      // Update attacker with surviving units, station at captured village
      _notifier.updateArmy(
        attacker.copyWith(
          units: survivingUnits,
          stationedAt: village.id,
          destination: null,
          turnsUntilArrival: 0,
        ),
      );
    }

    // Remove all defender armies
    for (final defender in defenders) {
      _notifier.removeArmy(defender.id);
    }

    // Transfer village ownership
    _notifier.transferVillageOwnership(village.id, attacker.owner);

    // Destroy garrison
    _notifier.modifyGarrison(village.id, -village.garrisonStrength);

    // Check if defender is eliminated
    _checkElimination(village.owner);
  }

  void _handleDefenderVictory(
    Army attacker,
    List<Army> defenders,
    Village village,
    CombatResult result,
  ) {
    // Attacker destroyed
    _notifier.removeArmy(attacker.id);

    // Apply defender casualties
    int remainingCasualties = result.defenderCasualties;

    for (final defender in defenders) {
      if (remainingCasualties <= 0) break;

      final casualties = remainingCasualties.clamp(0, defender.unitCount);
      remainingCasualties -= casualties;

      if (casualties >= defender.unitCount) {
        // Entire army destroyed
        _notifier.removeArmy(defender.id);
      } else {
        // Partial casualties
        final survivingUnits = defender.units.take(defender.unitCount - casualties).toList();
        _notifier.updateArmy(defender.copyWith(units: survivingUnits));
      }
    }

    // Apply garrison casualties
    _notifier.modifyGarrison(village.id, -result.garrisonCasualties);

    // Check if attacker is eliminated
    _checkElimination(attacker.owner);
  }

  void _checkElimination(PlayerId playerId) {
    if (playerId == PlayerId.neutral) return;

    final state = _notifier.currentState;
    final playerVillages = state.getPlayerVillages(playerId);
    final playerArmies = state.getPlayerArmies(playerId);

    // Eliminated if no villages and no armies
    if (playerVillages.isEmpty && playerArmies.isEmpty) {
      _notifier.eliminatePlayer(playerId);
    }

    // Check for victory
    _notifier.checkVictory();
  }

  /// Preview combat result without applying it (for UI).
  CombatPreview previewCombat({
    required GameState state,
    required ArmyId attackingArmyId,
    required VillageId villageId,
  }) {
    final attacker = state.getArmy(attackingArmyId);
    final village = state.getVillage(villageId);

    if (attacker == null || village == null) {
      return const CombatPreview(
        attackerStrength: 0,
        defenderStrength: 0,
        estimatedWinChance: 0,
      );
    }

    final defenders = state.getArmiesAt(villageId)
        .where((a) => a.owner == village.owner)
        .toList();

    final attackerStrength = _combatService.calculateStrength(attacker);
    final defenderStrength = _combatService.calculateDefenseStrength(
      defenders,
      village.garrisonStrength,
    );

    final winChance = _combatService.estimateWinProbability(
      attackerStrength: attackerStrength,
      defenderStrength: defenderStrength,
    );

    return CombatPreview(
      attackerStrength: attackerStrength,
      defenderStrength: defenderStrength,
      estimatedWinChance: winChance,
      defenderHasBonus: village.hasBuilding(BuildingType.fortress),
    );
  }
}

/// Preview information for combat.
class CombatPreview {
  final int attackerStrength;
  final int defenderStrength;
  final double estimatedWinChance;
  final bool defenderHasBonus;

  const CombatPreview({
    required this.attackerStrength,
    required this.defenderStrength,
    required this.estimatedWinChance,
    this.defenderHasBonus = false,
  });

  String get winChanceDisplay {
    final pct = (estimatedWinChance * 100).round();
    if (pct >= 80) return 'Very High ($pct%)';
    if (pct >= 60) return 'High ($pct%)';
    if (pct >= 40) return 'Even ($pct%)';
    if (pct >= 20) return 'Low ($pct%)';
    return 'Very Low ($pct%)';
  }
}
