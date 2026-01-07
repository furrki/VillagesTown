import '../../../core/types/typed_ids.dart';
import '../../../domain/entities/army.dart';
import '../../../domain/entities/game_state.dart';
import '../../../domain/entities/village.dart';
import '../../../domain/services/combat_service.dart';
import '../../../domain/services/movement_service.dart';
import '../../../domain/services/production_service.dart';
import '../../../domain/value_objects/resources.dart';
import '../../state/game_state_notifier.dart';

/// Events that occur during turn processing.
sealed class TurnEvent {
  const TurnEvent();
}

class ArmyArrivedEvent extends TurnEvent {
  final Army army;
  final Village destination;
  final bool isAttack;
  const ArmyArrivedEvent(this.army, this.destination, this.isAttack);
}

class BattleOccurredEvent extends TurnEvent {
  final BattleRecord battle;
  const BattleOccurredEvent(this.battle);
}

class VillageCapturedEvent extends TurnEvent {
  final Village village;
  final PlayerId previousOwner;
  final PlayerId newOwner;
  const VillageCapturedEvent(this.village, this.previousOwner, this.newOwner);
}

class PlayerEliminatedEvent extends TurnEvent {
  final PlayerId playerId;
  const PlayerEliminatedEvent(this.playerId);
}

class GameWonEvent extends TurnEvent {
  final PlayerId winnerId;
  const GameWonEvent(this.winnerId);
}

class ResourcesProducedEvent extends TurnEvent {
  final PlayerId playerId;
  final ResourceBundle produced;
  const ResourcesProducedEvent(this.playerId, this.produced);
}

/// Result of turn processing.
class TurnResult {
  final int turnNumber;
  final List<TurnEvent> events;
  final bool gameOver;
  final PlayerId? winner;

  const TurnResult({
    required this.turnNumber,
    required this.events,
    this.gameOver = false,
    this.winner,
  });
}

/// Use case for processing a complete game turn.
/// Orchestrates all turn phases in order.
class ProcessTurnUseCase {
  final GameStateNotifier _notifier;
  final CombatService _combatService;
  final MovementService _movementService;
  final ProductionService _productionService;

  const ProcessTurnUseCase(
    this._notifier,
    this._combatService,
    this._movementService,
    this._productionService,
  );

  /// Process a complete turn.
  /// Returns events that occurred for UI display.
  TurnResult execute() {
    final events = <TurnEvent>[];
    // ignore: unused_local_variable
    final initialState = _notifier.currentState;

    // Phase 1: Advance marching armies
    _advanceArmies();

    // Phase 2: Check for army arrivals and resolve battles
    events.addAll(_processArrivals());

    // Phase 3: Check for interceptions (armies crossing paths)
    events.addAll(_processInterceptions());

    // Phase 4: Production and resource generation
    events.addAll(_processProduction());

    // Phase 5: Population growth and happiness
    _processPopulationGrowth();

    // Phase 6: Garrison regeneration
    _processGarrisonRegen();

    // Phase 7: Check victory conditions
    _notifier.checkVictory();

    // Phase 8: Increment turn counter
    _notifier.incrementTurn();

    final finalState = _notifier.currentState;

    // Check for game end
    if (finalState.isGameOver) {
      events.add(GameWonEvent(finalState.winner!.id));
    }

    return TurnResult(
      turnNumber: finalState.currentTurn,
      events: events,
      gameOver: finalState.isGameOver,
      winner: finalState.winner?.id,
    );
  }

  /// Phase 1: Advance all marching armies.
  void _advanceArmies() {
    _notifier.advanceAllArmies();
  }

  /// Phase 2: Process army arrivals.
  List<TurnEvent> _processArrivals() {
    final events = <TurnEvent>[];
    final arrivingArmies = _movementService.getArrivingArmies(_notifier.currentState);

    for (final army in arrivingArmies) {
      if (army.destination == null) continue;

      final destination = _notifier.currentState.getVillage(army.destination!);
      if (destination == null) continue;

      final isAttack = destination.owner != army.owner;
      events.add(ArmyArrivedEvent(army, destination, isAttack));

      if (isAttack) {
        // Resolve combat
        final battleEvent = _resolveCombat(army, destination);
        if (battleEvent != null) {
          events.add(battleEvent);

          // Check for capture event
          final updatedVillage = _notifier.currentState.getVillage(destination.id);
          if (updatedVillage != null && updatedVillage.owner != destination.owner) {
            events.add(VillageCapturedEvent(
              updatedVillage,
              destination.owner,
              updatedVillage.owner,
            ));
          }
        }
      } else {
        // Friendly arrival - station the army
        _stationArmy(army, destination.id);
      }
    }

    // Check for eliminated players
    events.addAll(_checkEliminations());

    return events;
  }

  /// Resolve combat for an arriving army.
  BattleOccurredEvent? _resolveCombat(Army attacker, Village village) {
    final defenders = _notifier.currentState.getArmiesAt(village.id)
        .where((a) => a.owner == village.owner)
        .toList();

    final defenderUnits = defenders.expand((a) => a.units).toList();

    final result = _combatService.resolveCombat(
      attackers: attacker.units,
      defenders: defenderUnits,
      garrisonStrength: village.garrisonStrength,
      defenderHasBonus: village.defenseBonus > 0,
    );

    final battleRecord = _combatService.createBattleRecord(
      attacker: attacker,
      location: village,
      defenders: defenders,
      result: result,
    );

    _notifier.addPendingBattle(battleRecord);

    // Apply results
    if (result.attackerWon) {
      _handleAttackerVictory(attacker, defenders, village, result);
    } else {
      _handleDefenderVictory(attacker, defenders, village, result);
    }

    return BattleOccurredEvent(battleRecord);
  }

  void _handleAttackerVictory(
    Army attacker,
    List<Army> defenders,
    Village village,
    CombatResult result,
  ) {
    final survivingUnits = attacker.units.take(result.finalAttackerCount).toList();

    if (survivingUnits.isEmpty) {
      _notifier.removeArmy(attacker.id);
    } else {
      _notifier.updateArmy(attacker.copyWith(
        units: survivingUnits,
        stationedAt: village.id,
        destination: null,
        turnsUntilArrival: 0,
      ));
    }

    for (final defender in defenders) {
      _notifier.removeArmy(defender.id);
    }

    _notifier.transferVillageOwnership(village.id, attacker.owner);
    _notifier.modifyGarrison(village.id, -village.garrisonStrength);
  }

  void _handleDefenderVictory(
    Army attacker,
    List<Army> defenders,
    Village village,
    CombatResult result,
  ) {
    _notifier.removeArmy(attacker.id);

    int remainingCasualties = result.defenderCasualties;
    for (final defender in defenders) {
      if (remainingCasualties <= 0) break;

      final casualties = remainingCasualties.clamp(0, defender.unitCount);
      remainingCasualties -= casualties;

      if (casualties >= defender.unitCount) {
        _notifier.removeArmy(defender.id);
      } else {
        final survivingUnits = defender.units.take(defender.unitCount - casualties).toList();
        _notifier.updateArmy(defender.copyWith(units: survivingUnits));
      }
    }

    _notifier.modifyGarrison(village.id, -result.garrisonCasualties);
  }

  void _stationArmy(Army army, VillageId villageId) {
    _notifier.updateArmy(army.copyWith(
      stationedAt: villageId,
      destination: null,
      turnsUntilArrival: 0,
    ));

    // Auto-merge with existing armies at location
    _notifier.mergeArmiesAt(villageId, army.owner);
  }

  /// Phase 3: Process army interceptions.
  List<TurnEvent> _processInterceptions() {
    final events = <TurnEvent>[];
    final armies = _notifier.currentState.armies.values.where((a) => a.isMarching).toList();

    for (var i = 0; i < armies.length; i++) {
      for (var j = i + 1; j < armies.length; j++) {
        final interception = _movementService.checkInterception(
          state: _notifier.currentState,
          army1: armies[i],
          army2: armies[j],
        );

        if (interception != null) {
          final result = _combatService.resolveCombat(
            attackers: interception.army1.units,
            defenders: interception.army2.units,
            garrisonStrength: 0,
          );

          final battleRecord = BattleRecord(
            id: BattleId.generate(),
            attackerName: interception.army1.name,
            defenderName: interception.army2.name,
            attackerId: interception.army1.owner,
            defenderId: interception.army2.owner,
            originVillageId: interception.army1.origin,
            locationName: 'Field Battle',
            rounds: result.rounds,
            attackerWon: result.attackerWon,
            initialAttackerCount: interception.army1.unitCount,
            initialDefenderCount: interception.army2.unitCount,
            initialGarrisonCount: 0,
            timestamp: DateTime.now(),
            isPending: true,
          );

          _notifier.addPendingBattle(battleRecord);
          events.add(BattleOccurredEvent(battleRecord));

          // Apply interception results
          _applyInterceptionResults(interception, result);
        }
      }
    }

    return events;
  }

  void _applyInterceptionResults(InterceptionResult interception, CombatResult result) {
    if (result.attackerWon) {
      _notifier.removeArmy(interception.army2.id);
      if (result.finalAttackerCount > 0) {
        final survivors = interception.army1.units.take(result.finalAttackerCount).toList();
        _notifier.updateArmy(interception.army1.copyWith(units: survivors));
      } else {
        _notifier.removeArmy(interception.army1.id);
      }
    } else {
      _notifier.removeArmy(interception.army1.id);
      if (result.finalDefenderCount > 0) {
        final survivors = interception.army2.units.take(result.finalDefenderCount).toList();
        _notifier.updateArmy(interception.army2.copyWith(units: survivors));
      } else {
        _notifier.removeArmy(interception.army2.id);
      }
    }
  }

  /// Phase 4: Process resource production.
  List<TurnEvent> _processProduction() {
    final events = <TurnEvent>[];
    final state = _notifier.currentState;

    for (final player in state.activePlayers) {
      if (player.isNeutral) continue;

      var totalProduction = ResourceBundle.empty;

      for (final village in state.getPlayerVillages(player.id)) {
        final netChange = _productionService.calculateNetChange(village);
        totalProduction = totalProduction + netChange;

        // Update village resources
        final newResources = village.resources + netChange;
        _notifier.updateVillage(village.copyWith(resources: newResources));
      }

      if (totalProduction.isNotEmpty) {
        _notifier.modifyResources(player.id, totalProduction);
        events.add(ResourcesProducedEvent(player.id, totalProduction));
      }
    }

    return events;
  }

  /// Phase 5: Process population growth.
  void _processPopulationGrowth() {
    for (final village in _notifier.currentState.villages.values) {
      if (village.owner == PlayerId.neutral) continue;

      final popChange = _productionService.calculatePopulationGrowth(village);
      final happinessChange = _productionService.calculateHappinessChange(village);

      _notifier.updateVillage(village.copyWith(
        population: (village.population + popChange.delta).clamp(0, village.populationCap),
        happiness: (village.happiness + happinessChange + popChange.happinessDelta).clamp(0, 100),
      ));
    }
  }

  /// Phase 6: Process garrison regeneration.
  void _processGarrisonRegen() {
    for (final village in _notifier.currentState.villages.values) {
      if (village.owner == PlayerId.neutral) continue;

      final regen = _productionService.calculateGarrisonRegen(village);
      if (regen > 0) {
        _notifier.modifyGarrison(village.id, regen);
      }
    }
  }

  /// Check for player eliminations.
  List<TurnEvent> _checkEliminations() {
    final events = <TurnEvent>[];
    final state = _notifier.currentState;

    for (final player in state.players.values) {
      if (player.isEliminated || player.isNeutral) continue;

      final villages = state.getPlayerVillages(player.id);
      final armies = state.getPlayerArmies(player.id);

      if (villages.isEmpty && armies.isEmpty) {
        _notifier.eliminatePlayer(player.id);
        events.add(PlayerEliminatedEvent(player.id));
      }
    }

    return events;
  }
}
