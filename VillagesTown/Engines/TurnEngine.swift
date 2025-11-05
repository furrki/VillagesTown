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

        print("\n" + String(repeating: "=", count: 60))
        print("🎲 TURN \(game.currentTurn)")
        print(String(repeating: "=", count: 60) + "\n")

        // 0. Reset unit movement
        print("🔄 Phase 0: Reset Unit Movement")
        resetUnitMovement()

        // 1. Building Production
        print("\n📦 Phase 1: Building Production")
        doBuildingProduction()

        // 2. Tax Collection
        print("\n💰 Phase 2: Tax Collection")
        collectTaxes()

        // 3. Unit Upkeep
        print("\n💸 Phase 3: Unit Upkeep")
        processUnitUpkeep()

        // 4. Population & Happiness
        print("\n👥 Phase 4: Population & Happiness")
        processPopulation()

        // 5. Update happiness
        processHappiness()

        // 6. AI turns
        print("\n🤖 Phase 6: AI Turns")
        processAITurns()

        // 7. Check victory conditions
        print("\n🏆 Phase 7: Victory Check")
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

    private func processUnitUpkeep() {
        let units = GameManager.shared.map.units
        var villages = GameManager.shared.map.villages
        unitUpkeepEngine.processUpkeep(units: units, villages: &villages)
        GameManager.shared.map.villages = villages
    }

    private func resetUnitMovement() {
        var units = GameManager.shared.map.units
        movementEngine.resetMovement(for: &units)
        GameManager.shared.map.units = units
        print("✨ All units movement restored")
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
                let units = game.map.units.filter { $0.owner == player.id }
                print("   ✓ \(player.name): \(villages.count) villages, \(units.count) units")
            }
        }
        print("📊 Total units on map: \(game.map.units.count)")
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

