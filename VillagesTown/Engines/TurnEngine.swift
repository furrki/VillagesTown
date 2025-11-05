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

    func doTurn() {
        let game = GameManager.shared
        game.currentTurn += 1

        print("\n" + String(repeating: "=", count: 60))
        print("🎲 TURN \(game.currentTurn)")
        print(String(repeating: "=", count: 60) + "\n")

        // 1. Building Production
        print("📦 Phase 1: Building Production")
        doBuildingProduction()

        // 2. Tax Collection
        print("\n💰 Phase 2: Tax Collection")
        collectTaxes()

        // 3. Population & Happiness
        print("\n👥 Phase 3: Population & Happiness")
        processPopulation()

        // 4. Update happiness
        processHappiness()

        // Future phases:
        // 5. Unit upkeep
        // 6. AI turns
        // 7. Check victory conditions

        print("\n" + String(repeating: "=", count: 60))
        print("✅ Turn \(game.currentTurn) Complete")
        print(String(repeating: "=", count: 60) + "\n")
    }

    private func doBuildingProduction() {
        GameManager.shared.map.villages = GameManager.shared.map.villages.map { village in
            var mutableVillage = village
            BuildingProductionEngine.consumeAndProduceAll(in: &mutableVillage)
            return mutableVillage
        }
    }

    private func collectTaxes() {
        var villages = GameManager.shared.map.villages
        populationEngine.collectTaxes(for: &villages)
        GameManager.shared.map.villages = villages
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

