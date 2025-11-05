//
//  BuildingProductionEngine.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 12.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import Foundation

class BuildingProductionEngine {
    static func consumeAndProduceAll(in village: inout Village) {
        var totalProduction: [Resource: Int] = [:]

        for building in village.buildings {
            // Check if we can consume required resources
            if building.resourcesConsumption.isEmpty || village.substract(building.resourcesConsumption) {
                // Calculate production with bonuses
                let production = building.resourcesProduction

                // Apply village production bonus
                let bonus = village.productionBonus

                // Apply happiness modifier
                let happinessModifier: Double
                let happiness = village.totalHappiness
                if happiness >= 80 {
                    happinessModifier = 1.2 // +20% production
                } else if happiness < 50 {
                    happinessModifier = 0.8 // -20% production
                } else {
                    happinessModifier = 1.0
                }

                // Calculate final production
                var finalProduction: [Resource: Int] = [:]
                for (resource, amount) in production {
                    let finalAmount = Int(Double(amount) * (1 + bonus) * happinessModifier)
                    finalProduction[resource] = finalAmount

                    // Track total
                    totalProduction[resource, default: 0] += finalAmount
                }

                // Add resources
                village.add(finalProduction)

            } else {
                print("⚠️ \(village.name): \(building.name) couldn't work (insufficient resources)")
            }
        }

        // Print production summary if any
        if !totalProduction.isEmpty {
            var summary = "🏭 \(village.name) produced: "
            for (resource, amount) in totalProduction {
                summary += "\(resource.emoji)\(amount) "
            }
            print(summary)
        }
    }

    // Production for all villages
    static func produceForAllVillages(villages: inout [Village]) {
        for i in 0..<villages.count {
            consumeAndProduceAll(in: &villages[i])
        }
    }
}
