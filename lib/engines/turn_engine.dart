import '../data/models/army.dart';
import '../data/models/resource.dart';
import '../data/models/turn_event.dart';
import '../data/models/unit.dart';
import '../data/models/unit_type.dart';
import '../data/models/village.dart';
import 'ai_engine.dart';
import 'building_production_engine.dart';
import 'combat_engine.dart';
import 'game_manager.dart';
import 'population_engine.dart';

class TurnEngine {
  final PopulationEngine _populationEngine = PopulationEngine();
  final AIEngine _aiEngine = AIEngine();
  final CombatEngine _combatEngine = CombatEngine();

  void doTurn() {
    final game = GameManager.shared;
    game.currentTurn++;
    game.clearTurnEvents();

    // 0. Reset mobilization counters
    for (var i = 0; i < game.map.villages.length; i++) {
      game.map.villages[i].recruitsThisTurn = 0;
    }

    // 1. Building Production
    _doBuildingProduction();

    // 2. Tax Collection
    _collectTaxes();

    // 3. Army Upkeep
    _processArmyUpkeep();

    // 4. Population & Happiness
    _processPopulation();
    _processHappiness();

    // 6. Garrison Regeneration
    _processGarrisonRegeneration();

    // 7. Siege Combat (armies stationed at enemy villages)
    _processSiegeCombat();

    // 8. Mid-route Army Interception
    _processArmyInterception();

    // 9. Army Movement & Combat
    _processArmyMovement();

    // 9. AI Turns
    _processAITurns();

    // 10. Intelligence
    _detectIncomingEnemies();

    // 11. Auto-finalize AI vs AI battles
    game.finalizeAIBattles();

    // 12. Victory Check
    _checkVictory();

    // Notify is called by GameManager methods
  }

  void _doBuildingProduction() {
    final game = GameManager.shared;
    for (var i = 0; i < game.map.villages.length; i++) {
      BuildingProductionEngine.consumeAndProduceAll(game.map.villages[i]);
    }
    game.syncGlobalResources();
  }

  void _collectTaxes() {
    final game = GameManager.shared;
    final villages = game.map.villages.toList();
    _populationEngine.collectTaxes(villages);
    game.syncGlobalResources();
  }

  void _processArmyUpkeep() {
    final game = GameManager.shared;

    for (final player in game.players) {
      final totalUpkeep = <Resource, int>{};

      for (final army in game.getArmiesFor(player.id)) {
        for (final unit in army.units) {
          final stats = unit.unitType.stats;
          for (final entry in stats.upkeep.entries) {
            totalUpkeep[entry.key] = (totalUpkeep[entry.key] ?? 0) + entry.value;
          }
        }
      }

      for (final entry in totalUpkeep.entries) {
        game.modifyGlobalResource(player.id, entry.key, -entry.value);
      }
    }
  }

  void _processPopulation() {
    final game = GameManager.shared;
    final villages = game.map.villages.toList();
    _populationEngine.processPopulationGrowth(villages);
    game.map.villages = villages;
  }

  void _processHappiness() {
    final game = GameManager.shared;
    final villages = game.map.villages.toList();
    _populationEngine.processHappiness(villages);
    game.map.villages = villages;
  }

  void _processGarrisonRegeneration() {
    final game = GameManager.shared;
    for (var i = 0; i < game.map.villages.length; i++) {
      if (game.map.villages[i].owner != 'neutral') {
        game.map.villages[i].regenerateGarrison();
      }
    }
  }

  void _processSiegeCombat() {
    final game = GameManager.shared;

    // Find armies stationed at enemy villages
    final siegeArmies = <(Army, Village)>[];
    for (final army in game.armies) {
      if (army.isMarching) continue;
      final villageId = army.stationedAt;
      if (villageId == null) continue;

      final village = game.map.villages.cast<Village?>().firstWhere(
        (v) => v!.id == villageId,
        orElse: () => null,
      );
      if (village == null) continue;

      // Army at enemy village - should attack
      if (army.owner != village.owner) {
        siegeArmies.add((army, village));
      }
    }

    // Resolve siege combat
    for (final (army, village) in siegeArmies) {
      _resolveCombat(army, village);
    }
  }

  void _processArmyInterception() {
    final game = GameManager.shared;
    final marchingArmies = game.armies.where((a) => a.isMarching).toList();

    final processedPairs = <String>{};
    final interceptedArmyIds = <String>{};

    for (final army1 in marchingArmies) {
      for (final army2 in marchingArmies) {
        if (army1.id == army2.id) continue;
        if (army1.owner == army2.owner) continue;
        if (interceptedArmyIds.contains(army1.id)) continue;
        if (interceptedArmyIds.contains(army2.id)) continue;

        final pairKey = [army1.id, army2.id]..sort();
        final key = pairKey.join('-');
        if (processedPairs.contains(key)) continue;
        processedPairs.add(key);

        // Check if armies intercept:
        // 1. Same path opposite directions (will pass each other)
        final oppositeDirection = army1.destination == army2.origin && army1.origin == army2.destination;

        // 2. Same destination, close to each other
        final sameDestination = army1.destination == army2.destination;
        final bothCloseToArrival = army1.turnsUntilArrival <= 1 && army2.turnsUntilArrival <= 1;

        // 3. One army's destination is the other's origin (pursuing)
        final pursuing = army1.destination == army2.origin || army2.destination == army1.origin;
        final closeEnough = (army1.turnsUntilArrival - army2.turnsUntilArrival).abs() <= 1;

        final shouldIntercept = oppositeDirection ||
            (sameDestination && bothCloseToArrival) ||
            (pursuing && closeEnough && army1.turnsUntilArrival <= 1);

        if (shouldIntercept) {
          game.addTurnEvent(ArmyInterceptedEvent(
            army1Name: army1.name,
            army2Name: army2.name,
          ));
          _resolveFieldBattle(army1.id, army2.id);
          interceptedArmyIds.add(army1.id);
          interceptedArmyIds.add(army2.id);
        }
      }
    }
  }

  void _resolveFieldBattle(String army1Id, String army2Id) {
    final game = GameManager.shared;

    final army1 = game.armies.cast<Army?>().firstWhere((a) => a!.id == army1Id, orElse: () => null);
    final army2 = game.armies.cast<Army?>().firstWhere((a) => a!.id == army2Id, orElse: () => null);

    if (army1 == null || army2 == null) return;

    // Check for existing pending battle to prevent duplicates
    final existing = game.pendingBattles.any((b) => b.attackerId == army1Id && b.defenderId == army2Id);
    if (existing) return;

    final result = _combatEngine.resolveCombat(
      attackerName: army1.name,
      defenderName: army2.name,
      attackerId: army1.id,
      defenderId: army2.id,
      originVillageId: army1.stationedAt,
      attackers: army1.units,
      defenders: army2.units,
      map: game.map,
      defendingVillage: null,
    );
    
    // Store record for later viewing only if actual combat occurred
    if (result.rounds.isNotEmpty) {
      game.pendingBattles.add(result);
    }
    
    // Defer consequences to GameManager.finalizeBattle
  }

  void _processArmyMovement() {
    final game = GameManager.shared;
    final arrivedArmies = <(Army, Village, String?)>[]; // Added origin

    // Advance all marching armies
    for (var i = 0; i < game.armies.length; i++) {
      if (game.armies[i].isMarching) {
        // Save origin BEFORE advancing (advanceMarch clears it)
        final originBeforeAdvance = game.armies[i].origin;
        game.armies[i].advanceMarch();

        if (!game.armies[i].isMarching) {
          final destId = game.armies[i].stationedAt;
          if (destId != null) {
            final destination = game.map.villages.cast<Village?>().firstWhere(
                  (v) => v!.id == destId,
                  orElse: () => null,
                );
            if (destination != null) {
              arrivedArmies.add((game.armies[i], destination, originBeforeAdvance));
            }
          }
        }
      }
    }

    // Process arrivals
    for (final (army, destination, origin) in arrivedArmies) {
      if (army.owner != destination.owner) {
        _resolveCombat(army, destination, savedOrigin: origin);
      } else {
        game.mergeArmiesAt(destination.id, army.owner);
        game.addTurnEvent(ArmyArrivedEvent(armyName: army.name, destination: destination.name));
      }
    }
  }

  void _resolveCombat(Army attacker, Village village, {String? savedOrigin}) {
    final game = GameManager.shared;

    // Check for existing pending battle to prevent duplicates
    final existing = game.pendingBattles.any((b) => b.attackerId == attacker.id && b.defenderId == village.id);
    if (existing) return;

    // Mark village as under siege
    village.underSiege = true;

    // Get defending armies (exclude the attacker!)
    final defenderArmies = game.getArmiesAt(village.id)
        .where((a) => a.owner == village.owner && a.id != attacker.id)
        .toList();
    final defenderUnits = defenderArmies.expand((a) => a.units).toList();

    // Create virtual garrison militia units (Empire Total War style - garrison defends but never moves)
    final garrisonUnits = List.generate(
      village.garrisonStrength,
      (_) => Unit.create(UnitType.militia, village.owner, village.coordinates),
    );
    final allDefenders = [...defenderUnits, ...garrisonUnits];

    final result = _combatEngine.resolveCombat(
      attackerName: attacker.name,
      defenderName: game.getVillageDisplayName(village),
      attackerId: attacker.id,
      defenderId: village.id,
      originVillageId: savedOrigin ?? attacker.origin,
      attackers: attacker.units,
      defenders: allDefenders,
      map: game.map,
      defendingVillage: village,
      garrisonCount: village.garrisonStrength,
    );
    
    if (result.rounds.isNotEmpty) {
      game.pendingBattles.add(result);
    }

    // Defer consequences to GameManager.finalizeBattle
  }

  /// Trigger combat immediately (called when attacking enemy village)
  void triggerImmediateCombat(Army attacker, Village village, String originVillageId) {
    _resolveCombat(attacker, village, savedOrigin: originVillageId);
  }

  void _processAITurns() {
    final game = GameManager.shared;
    final aiPlayers = game.players.where((p) => !p.isHuman && !p.isEliminated).toList();

    for (final aiPlayer in aiPlayers) {
      _aiEngine.executeAITurn(aiPlayer, game.map);
    }
  }

  void _detectIncomingEnemies() {
    final game = GameManager.shared;
    final playerVillages = game.getPlayerVillages('player');

    for (final army in game.armies) {
      if (army.owner == 'player') continue;
      if (!army.isMarching) continue;

      final destId = army.destination;
      if (destId == null) continue;

      if (playerVillages.any((v) => v.id == destId)) {
        final destVillage = game.map.villages.cast<Village?>().firstWhere(
              (v) => v!.id == destId,
              orElse: () => null,
            );
        if (destVillage != null) {
          game.addTurnEvent(EnemyApproachingEvent(
            enemyName: army.name,
            target: destVillage.name,
            turns: army.turnsUntilArrival,
          ));
        }
      }
    }
  }

  void _checkVictory() {
    final game = GameManager.shared;

    for (var i = 0; i < game.players.length; i++) {
      final playerId = game.players[i].id;
      final playerVillages = game.map.villages.where((v) => v.owner == playerId);

      if (playerVillages.isEmpty && !game.players[i].isEliminated) {
        game.players[i] = game.players[i].copyWith(isEliminated: true);

        // Remove all armies of eliminated player (they have no home to return to)
        game.armies.removeWhere((a) => a.owner == playerId);
      }
    }
  }
}
