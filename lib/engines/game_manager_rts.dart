part of 'game_manager.dart';

extension GameManagerRts on GameManager {
  /// Check all active missions for objective completion.
  void checkMissions([String? arrivedCityId]) {
    final pc = playerCharacter;
    if (pc == null) return;

    for (final mission in pc.activeMissions) {
      if (mission.state != MissionState.active) continue;
      mission.checkExpiry(gameLoop.tickCount);
      if (mission.state != MissionState.active) continue;

      for (final obj in mission.objectives) {
        if (obj.completed) continue;

        switch (obj.type) {
          case ObjectiveType.travelTo:
            if (arrivedCityId != null && obj.targetCityId == arrivedCityId) {
              // For delivery missions, check cargo requirement first
              final cargoObj = mission.objectives
                  .where((o) => o.type == ObjectiveType.haveCargo)
                  .firstOrNull;
              if (cargoObj == null || _checkCargoObjective(cargoObj, pc)) {
                obj.markComplete();
                cargoObj?.markComplete();
              }
            }
          case ObjectiveType.haveCargo:
            if (!mission.objectives.any((o) => o.type == ObjectiveType.travelTo)) {
              _checkCargoObjective(obj, pc);
            } else {
              obj.currentAmount = pc.cargoOf(TradeGood.values.firstWhere((g) => g.name == obj.targetGoodName, orElse: () => TradeGood.grain));
              obj.completed = false;
            }
          case ObjectiveType.winBattles:
            if (pc.battlesWon >= obj.targetAmount) obj.markComplete();
          case ObjectiveType.recruitUnits:
            final warband = playerWarband;
            if (warband != null && warband.unitCount >= obj.targetAmount) {
              obj.markComplete();
            }
          case ObjectiveType.earnGold:
            if (pc.totalGoldEarned >= obj.targetAmount) obj.markComplete();
          case ObjectiveType.deliverGoods:
            break; // handled via travelTo + haveCargo combo
        }
      }

      mission.checkCompletion();
      if (mission.state == MissionState.completed) {
        _completeMission(mission);
      }
    }

    // Move completed/failed missions
    pc.activeMissions.removeWhere((m) =>
        m.state == MissionState.completed || m.state == MissionState.failed);
  }

  bool _checkCargoObjective(MissionObjective obj, PlayerCharacter pc) {
    if (obj.targetGoodName == null) return true;
    final good = TradeGood.values.where((g) => g.name == obj.targetGoodName).firstOrNull;
    if (good == null) return false;
    final amount = pc.cargoOf(good);
    obj.currentAmount = amount;
    if (amount >= obj.targetAmount) {
      obj.markComplete();
      return true;
    }
    return false;
  }

  void _completeMission(Mission mission) {
    final pc = playerCharacter;
    if (pc == null) return;
    if (mission.goldReward > 0) awardGold(mission.goldReward);
    if (mission.reputationReward > 0 && mission.reputationFactionId != null) {
      pc.addReputation(mission.reputationFactionId!, mission.reputationReward);
    }
    pc.contractsCompleted++;
    pc.completedMissions.add(mission);

    final reward = mission.goldReward > 0 ? ' (+${mission.goldReward}g)' : '';
    pendingNotifications.add('Mission complete: ${mission.title}$reward');
  }

  /// Start traveling from current city to a connected city.
  bool startTravel(String destinationCityId) {
    final pc = playerCharacter;
    if (pc == null || pc.state != PlayerState.atCity) return false;
    if (pc.currentCityId == null) return false;
    if (!areNeighbors(pc.currentCityId!, destinationCityId)) return false;

    final origin = getVillageById(pc.currentCityId);
    final dest = getVillageById(destinationCityId);
    if (origin == null || dest == null) return false;

    final baseTicks = Army.calculateTravelTime(origin.coordinates, dest.coordinates);
    final ticks = (baseTicks / pc.travelSpeedModifier).ceil().clamp(3, 30);

    pc.state = PlayerState.traveling;
    pc.travelOriginId = pc.currentCityId;
    pc.travelDestinationId = destinationCityId;
    pc.travelProgress = 0.0;
    pc.travelTotalTicks = ticks;
    pc.currentCityId = null;

    currentEncounter = null;
    gameLoop.start();

    // Move player's warband with them (unstation from origin)
    final warband = playerWarband;
    if (warband != null && warband.stationedAt == pc.travelOriginId) {
      warband.stationedAt = null;
      updateArmy(warband);
    }

    notifyListeners();
    return true;
  }

  /// Dismiss current encounter and resume travel.
  void dismissEncounter() {
    currentEncounter = null;
    lastBattleReport = null;
    if (playerCharacter?.state == PlayerState.traveling) {
      gameLoop.start();
    }
    notifyListeners();
  }

  /// Get the village the player is currently at (or null if traveling).
  Village? get playerCurrentCity {
    final id = playerCharacter?.currentCityId;
    if (id == null) return null;
    return getVillageById(id);
  }

  /// Get connected cities from the player's current location.
  List<Village> get travelDestinations {
    final id = playerCharacter?.currentCityId;
    if (id == null) return [];
    return getNeighbors(id);
  }


  /// Adds [units] to the warband, or raises a new one where the character is when it was lost.
  void _joinWarband(List<Unit> units) {
    final pc = playerCharacter!;
    final warband = playerWarband;
    if (warband != null) {
      warband.addUnits(units);
      updateArmy(warband);
      return;
    }
    final army = createArmy(units, pc.currentCityId ?? pc.travelOriginId ?? '', 'player');
    if (pc.state == PlayerState.traveling) army.stationedAt = null;
    pc.warbandId = army.id;
  }

  bool recruitToWarband(UnitType unitType, Village city) {
    final pc = playerCharacter;
    if (pc == null || pc.currentCityId != city.id) return false;

    // Check warband size limit
    final warband = playerWarband;
    final currentSize = warband?.unitCount ?? 0;
    if (currentSize >= pc.maxWarbandSize) return false;

    // Check required building
    final recruitEngine = RecruitmentEngine();
    final reqBuilding = recruitEngine.getRequiredBuilding(unitType);
    if (reqBuilding != null && !city.buildings.any((b) => b.name == reqBuilding)) return false;

    final goldCost = recruitEngine.recruitCost(unitType, 1)[Resource.gold] ?? 0;
    if (!spendGold(goldCost)) return false;

    _joinWarband([Unit.create(unitType, 'player', city.coordinates)]);
    notifyListeners();
    return true;
  }

  bool buyPackMule() {
    final pc = playerCharacter;
    if (pc == null) return false;
    if (!spendGold(50)) return false;
    pc.packMules++;
    notifyListeners();
    return true;
  }

  bool buyTradeWagon() {
    final pc = playerCharacter;
    if (pc == null) return false;
    if (!spendGold(200)) return false;
    pc.tradeWagons++;
    notifyListeners();
    return true;
  }

  /// Fight an encounter's band. The warband keeps its wounds, loses its real dead, and a beaten
  /// warband runs with its survivors instead of dying to the last man.
  EncounterBattleReport? resolveEncounterBattle(Encounter encounter, BattlePlan plan) {
    final pc = playerCharacter;
    final warband = playerWarband;
    final enemies = encounter.enemyUnits;
    if (pc == null || warband == null || warband.units.isEmpty || enemies == null || enemies.isEmpty) return null;

    final before = warband.unitCount;
    final tactics = plan.toTactics(warband);
    final result = CombatEngine().resolveCombat(
      attackerName: warband.name,
      defenderName: encounter.type == EncounterType.deserters ? 'Deserters' : 'Bandits',
      attackerId: warband.id,
      defenderId: 'encounter',
      attackerOwnerId: 'player',
      defenderOwnerId: 'bandits',
      attackers: warband.units,
      defenders: enemies,
      map: map,
      attackerFormation: tactics.formation,
      attackerTactics: tactics,
      attackerFatigueMod: 1 + pc.combatBonus,
      writeAttackerWounds: true,
      routBelow: GameManager.encounterRoutBelow,
    );
    warband.removeDeadUnits();

    final won = result.attackerWon;
    var goldGained = 0;
    var goldLost = 0;
    var cargoLost = 0;
    if (won) {
      goldGained = encounter.goldReward ?? 0;
      awardGold(goldGained);
      pc.battlesWon++;
      // One skill level per three wins: intimidate opens at 3, and combat stays within the 1-10 skill range.
      if (pc.battlesWon % 3 == 0) pc.combatSkill = min(pc.combatSkill + 1, 10);
      battlesWon['player'] = (battlesWon['player'] ?? 0) + 1;
      for (final u in warband.units) {
        u.gainExperience(25);
      }
    } else {
      battlesLost++;
      goldLost = min((gold * 0.3).round(), 150);
      spendGold(goldLost);
      for (final good in pc.cargo.keys.toList()) {
        final lost = (pc.cargoOf(good) * 0.3).ceil();
        cargoLost += lost;
        pc.removeCargo(good, lost);
      }
      for (final u in warband.units) {
        u.gainExperience(10);
      }
    }

    if (warband.units.isEmpty) {
      removeArmy(warband.id);
    } else {
      updateArmy(warband);
    }

    lastBattleReport = EncounterBattleReport(
      won: won,
      plan: plan,
      enemies: enemies.length,
      killed: before - warband.unitCount,
      wounded: warband.units.where((u) => u.currentHP < u.maxHP).length,
      goldGained: goldGained,
      goldLost: goldLost,
      cargoLost: cargoLost,
    );
    pc.checkProgression();
    notifyListeners();
    return lastBattleReport;
  }

  /// Flee from encounter. Costs: -10 rep, lose 25% cargo, 1 soldier dies.
  void fleeEncounter() {
    final pc = playerCharacter;
    if (pc == null) return;

    // Lose 25% of each cargo
    for (final good in pc.cargo.keys.toList()) {
      final amount = pc.cargo[good] ?? 0;
      final lost = (amount * 0.25).ceil();
      if (lost > 0) pc.removeCargo(good, lost);
    }

    // Lose 1 soldier as rearguard
    final warband = playerWarband;
    if (warband != null && warband.units.isNotEmpty) {
      warband.units.last.takeDamage(9999);
      warband.removeDeadUnits();
      if (warband.units.isEmpty) {
        removeArmy(warband.id);
      } else {
        updateArmy(warband);
      }
    }

    dismissEncounter();
  }

  /// Resolve a narrative encounter choice.
  /// Returns the result text to display, or null on failure.
  String? resolveEncounterChoice(Encounter encounter, EncounterChoice choice) {
    final pc = playerCharacter;
    if (pc == null) return null;

    switch (choice.outcome) {
      case EncounterChoiceOutcome.fight:
        // Fight is handled separately via resolveEncounterBattle
        return null;

      case EncounterChoiceOutcome.flee:
        fleeEncounter();
        return choice.resultText;

      case EncounterChoiceOutcome.payGold:
        final cost = choice.goldAmount ?? 0;
        if (!spendGold(cost)) return null;
        dismissEncounter();
        notifyListeners();
        return choice.resultText;

      case EncounterChoiceOutcome.gainGold:
        awardGold(choice.goldAmount ?? 0);
        dismissEncounter();
        notifyListeners();
        return choice.resultText;

      case EncounterChoiceOutcome.gainCargo:
        final cost = choice.goldAmount ?? 0;
        if (gold < cost) return null;
        if (choice.tradeGood != null) {
          final space = pc.totalCargoCapacity - pc.currentCargoCount;
          if (space < (choice.tradeGoodAmount ?? 1)) return null;
          spendGold(cost);
          pc.addCargo(choice.tradeGood!, choice.tradeGoodAmount ?? 1);
        }
        dismissEncounter();
        notifyListeners();
        return choice.resultText;

      case EncounterChoiceOutcome.recruitUnit:
        final unitType = choice.unitType ?? encounter.recruitableUnit;
        if (unitType == null) return null;
        final warband = playerWarband;
        final currentSize = warband?.unitCount ?? 0;
        if (currentSize >= pc.maxWarbandSize) return null;
        _joinWarband([Unit.create(unitType, 'player', const GeoCoordinate(0, 0))]);
        dismissEncounter();
        notifyListeners();
        return choice.resultText;

      case EncounterChoiceOutcome.dismiss:
        dismissEncounter();
        notifyListeners();
        return choice.resultText;

      case EncounterChoiceOutcome.loseGold:
        final amount = choice.goldAmount ?? 0;
        spendGold(min(amount, gold));
        dismissEncounter();
        notifyListeners();
        return choice.resultText;

      case EncounterChoiceOutcome.loseCargo:
        if (choice.tradeGood != null) {
          pc.removeCargo(choice.tradeGood!, choice.tradeGoodAmount ?? 1);
        }
        dismissEncounter();
        notifyListeners();
        return choice.resultText;

      case EncounterChoiceOutcome.gainReputation:
        // Could be wired to faction rep later
        dismissEncounter();
        notifyListeners();
        return choice.resultText;
    }
  }

  /// Recruit a wounded soldier from encounter.
  bool recruitWoundedSoldier(Encounter encounter) {
    final pc = playerCharacter;
    if (pc == null) return false;
    if (encounter.recruitableUnit == null) return false;

    final warband = playerWarband;
    final currentSize = warband?.unitCount ?? 0;
    if (currentSize >= pc.maxWarbandSize) return false;

    final unit = Unit.create(encounter.recruitableUnit!, 'player', const GeoCoordinate(0, 0));
    // Wounded: half HP
    unit.takeDamage(unit.maxHP ~/ 2);
    _joinWarband([unit]);
    notifyListeners();
    return true;
  }
}
