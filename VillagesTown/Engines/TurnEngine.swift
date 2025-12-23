//
//  TurnEngine.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 12.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import Foundation

class TurnEngine {
    let populationEngine = PopulationEngine()
    let unitUpkeepEngine = UnitUpkeepEngine()
    let movementEngine = MovementEngine()
    let aiEngine = AIEngine()

    func doTurn() {
        let game = GameManager.shared
        game.currentTurn += 1
        game.clearTurnEvents()

        print("\n" + String(repeating: "=", count: 60))
        print("🎲 TURN \(game.currentTurn)")
        print(String(repeating: "=", count: 60) + "\n")

        // 1. Building Production
        print("\n📦 Phase 1: Building Production")
        doBuildingProduction()

        // 2. Tax Collection
        print("\n💰 Phase 2: Tax Collection")
        collectTaxes()

        // 3. Army Upkeep (replaces unit upkeep)
        print("\n💸 Phase 3: Army Upkeep")
        processArmyUpkeep()

        // 4. Population & Happiness
        print("\n👥 Phase 4: Population & Happiness")
        processPopulation()

        // 5. Update happiness
        processHappiness()

        // 6. Process Army Movement & Combat
        print("\n⚔️ Phase 6: Army Movement & Combat")
        processArmyMovement()

        // 7. AI turns
        print("\n🤖 Phase 7: AI Turns")
        processAITurns()

        // 8. Detect incoming enemies
        print("\n👁️ Phase 8: Intelligence")
        detectIncomingEnemies()

        // 9. Check victory conditions
        print("\n🏆 Phase 9: Victory Check")
        checkVictory()

        print("\n" + String(repeating: "=", count: 60))
        print("✅ Turn \(game.currentTurn) Complete")
        printGameStatus()
        print(String(repeating: "=", count: 60) + "\n")
    }

    private func doBuildingProduction() {
        GameManager.shared.map.villages = GameManager.shared.map.villages.map { village in
            var mutableVillage = village
            BuildingProductionEngine.consumeAndProduceAll(in: &mutableVillage)
            return mutableVillage
        }

        // Sync all village resources to global pool
        GameManager.shared.syncGlobalResources()
    }

    private func collectTaxes() {
        var villages = GameManager.shared.map.villages
        populationEngine.collectTaxes(for: &villages)
        GameManager.shared.map.villages = villages

        // Sync to global pool
        GameManager.shared.syncGlobalResources()
    }

    private func processPopulation() {
        var villages = GameManager.shared.map.villages
        populationEngine.processPopulationGrowth(for: &villages)
        GameManager.shared.map.villages = villages
    }

    private func processHappiness() {
        var villages = GameManager.shared.map.villages
        populationEngine.processHappiness(for: &villages)
        GameManager.shared.map.villages = villages
    }

    private func processArmyUpkeep() {
        let game = GameManager.shared

        // Calculate total upkeep for each player's armies
        for player in game.players {
            var totalUpkeep: [Resource: Int] = [:]

            for army in game.getArmiesFor(playerID: player.id) {
                for unit in army.units {
                    let stats = Unit.getStats(for: unit.unitType)
                    for (resource, amount) in stats.upkeep {
                        totalUpkeep[resource, default: 0] += amount
                    }
                }
            }

            // Deduct upkeep
            for (resource, amount) in totalUpkeep {
                game.modifyGlobalResource(playerID: player.id, resource: resource, amount: -amount)
            }

            if !totalUpkeep.isEmpty {
                print("   \(player.name) army upkeep: \(totalUpkeep)")
            }
        }
    }

    private func processArmyMovement() {
        let game = GameManager.shared
        var arrivedArmies: [(Army, Village)] = []

        // Advance all marching armies
        for i in game.armies.indices {
            if game.armies[i].isMarching {
                game.armies[i].advanceMarch()

                // Check for arrival
                if !game.armies[i].isMarching,
                   let destID = game.armies[i].stationedAt,
                   let destination = game.map.villages.first(where: { $0.id == destID }) {
                    arrivedArmies.append((game.armies[i], destination))
                }
            }
        }

        // Process arrivals (combat if enemy, merge if friendly)
        for (army, destination) in arrivedArmies {
            if army.owner != destination.owner {
                // COMBAT!
                resolveCombat(attacker: army, at: destination)
            } else {
                // Friendly arrival - merge armies
                game.mergeArmiesAt(villageID: destination.id, owner: army.owner)
                game.addTurnEvent(.armyArrived(armyName: army.name, destination: destination.name))
                print("   \(army.name) arrived at friendly \(destination.name)")
            }
        }
    }

    private func resolveCombat(attacker: Army, at village: Village) {
        let game = GameManager.shared
        let combatEngine = CombatEngine()

        // Get defending armies
        let defenderArmies = game.getArmiesAt(villageID: village.id).filter { $0.owner == village.owner }
        var defenderUnits: [Unit] = defenderArmies.flatMap { $0.units }
        var attackerUnits = attacker.units

        // Resolve combat
        let result = combatEngine.resolveCombat(
            attackers: &attackerUnits,
            defenders: &defenderUnits,
            location: village.coordinates,
            map: game.map,
            defendingVillage: village
        )

        // Update attacker army
        if var mutableArmy = game.armies.first(where: { $0.id == attacker.id }) {
            mutableArmy.units = attackerUnits.filter { $0.isAlive }
            mutableArmy.removeDeadUnits()

            if mutableArmy.units.isEmpty {
                game.removeArmy(mutableArmy.id)
            } else {
                game.updateArmy(mutableArmy)
            }
        }

        // Update defender armies
        for defArmy in defenderArmies {
            game.removeArmy(defArmy.id)
        }
        // Create new defender army with survivors
        let survivingDefenders = defenderUnits.filter { $0.isAlive }
        if !survivingDefenders.isEmpty {
            _ = game.createArmy(units: survivingDefenders, stationedAt: village.id, owner: village.owner)
        }

        // Handle village conquest
        if result.attackerWon && survivingDefenders.isEmpty {
            var mutableVillage = village
            let oldOwner = mutableVillage.owner
            mutableVillage.owner = attacker.owner
            mutableVillage.population = Int(Double(mutableVillage.population) * 0.7)
            mutableVillage.happiness -= 30
            game.updateVillage(mutableVillage)

            // Station attacking army at village
            if var attackingArmy = game.armies.first(where: { $0.id == attacker.id }) {
                attackingArmy.station(at: village.id)
                game.updateArmy(attackingArmy)
            }

            if attacker.owner == "player" {
                game.addTurnEvent(.villageConquered(villageName: village.name))
            } else if oldOwner == "player" {
                game.addTurnEvent(.villageLost(villageName: village.name))
            }
            print("   🏆 \(attacker.name) conquered \(village.name)!")
        } else if result.attackerWon {
            if attacker.owner == "player" {
                game.addTurnEvent(.battleWon(location: village.name, casualties: result.attackerCasualties))
            } else if village.owner == "player" {
                game.addTurnEvent(.battleLost(location: village.name, casualties: result.defenderCasualties))
            }
            print("   ⚔️ \(attacker.name) won battle at \(village.name) but defenders remain")
        } else {
            if attacker.owner == "player" {
                game.addTurnEvent(.battleLost(location: village.name, casualties: result.attackerCasualties))
            } else if village.owner == "player" {
                game.addTurnEvent(.battleWon(location: village.name, casualties: result.defenderCasualties))
            }
            print("   ❌ \(attacker.name) defeated at \(village.name)")
        }
    }

    private func detectIncomingEnemies() {
        let game = GameManager.shared
        let playerVillages = game.getPlayerVillages(playerID: "player")

        for army in game.armies where army.owner != "player" && army.isMarching {
            if let destID = army.destination,
               playerVillages.contains(where: { $0.id == destID }),
               let destVillage = game.map.villages.first(where: { $0.id == destID }) {
                game.addTurnEvent(.enemyApproaching(
                    enemyName: army.name,
                    target: destVillage.name,
                    turns: army.turnsUntilArrival
                ))
            }
        }
    }

    private func processAITurns() {
        let game = GameManager.shared

        // Get all AI players
        let aiPlayers = game.players.filter { !$0.isHuman && !$0.isEliminated }

        if aiPlayers.isEmpty {
            print("No active AI players")
            return
        }

        // Each AI takes their turn
        for aiPlayer in aiPlayers {
            aiEngine.executeAITurn(for: aiPlayer, map: &game.map)
        }
    }

    private func checkVictory() {
        let game = GameManager.shared

        // Check each player
        for i in 0..<game.players.count {
            let playerVillages = game.map.villages.filter { $0.owner == game.players[i].id }

            // Eliminate if no villages
            if playerVillages.isEmpty && !game.players[i].isEliminated {
                game.players[i].isEliminated = true
                print("💀 \(game.players[i].name) has been eliminated!")
            }
        }

        // Check for overall victory
        let activePlayers = game.players.filter { !$0.isEliminated }

        if activePlayers.count == 1 {
            let winner = activePlayers[0]
            print("🎉🎉🎉 \(winner.name) HAS WON THE GAME! 🎉🎉🎉")
            print("Victory by Domination!")
        }

        // Check for player defeat
        let player = game.players.first(where: { $0.isHuman })
        if player?.isEliminated == true {
            print("💔 You have been defeated!")
        }
    }

    private func printGameStatus() {
        let game = GameManager.shared

        print("📊 Game Status:")
        for player in game.players {
            if player.isEliminated {
                print("   ❌ \(player.name): ELIMINATED")
            } else {
                let villages = game.map.villages.filter { $0.owner == player.id }
                let armies = game.getArmiesFor(playerID: player.id)
                let totalUnits = armies.reduce(0) { $0 + $1.unitCount }
                let marchingArmies = armies.filter { $0.isMarching }.count
                print("   ✓ \(player.name): \(villages.count) villages, \(armies.count) armies (\(totalUnits) units, \(marchingArmies) marching)")
            }
        }
        print("📊 Total armies: \(game.armies.count)")
    }

    // MARK: - Legacy compatibility
    static func doBuildingProduction(game: inout GameManager) {
        for index in game.map.villages.indices {
            BuildingProductionEngine.consumeAndProduceAll(in: &game.map.villages[index])
        }
    }

    static func doTurn(game: inout GameManager) {
        GameManager.shared.turnEngine.doTurn()
    }
}

