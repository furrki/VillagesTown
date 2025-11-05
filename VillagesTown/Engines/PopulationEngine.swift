//
//  PopulationEngine.swift
//  VillagesTown
//
//  Created by Claude Code
//

import Foundation

class PopulationEngine {

    // MARK: - Population Growth
    func processPopulationGrowth(for villages: inout [Village]) {
        for i in 0..<villages.count {
            var village = villages[i]

            // Check food availability
            let foodNeeded = village.population
            let currentFood = village.resources[.food] ?? 0

            if currentFood >= foodNeeded {
                // Enough food - population grows
                growPopulation(village: &village)
                // Consume food
                village.substract(.food, amount: foodNeeded)
            } else {
                // Starvation - population decreases
                starvePopulation(village: &village)
                // Consume all available food
                village.substract(.food, amount: currentFood)
            }

            villages[i] = village
        }
    }

    private func growPopulation(village: inout Village) {
        // Base growth rate 2%
        var growthRate = 0.02

        // Happiness bonus
        let happiness = village.totalHappiness
        if happiness >= 80 {
            growthRate += 0.01 // +1% if very happy
        } else if happiness < 50 {
            growthRate -= 0.01 // -1% if unhappy
        }

        // Hospital bonus
        if village.buildings.contains(where: { $0.name == "Hospital" }) {
            growthRate += 0.015 // +1.5%
        }

        // Check if at capacity
        if village.population >= village.populationCapacity {
            growthRate = 0
        }

        let growth = Int(Double(village.population) * growthRate)
        village.modifyPopulation(by: growth)

        if growth > 0 {
            print("📈 \(village.name): Population grew by \(growth) (now \(village.population))")
        }
    }

    private func starvePopulation(village: inout Village) {
        // Starvation causes 10% population loss
        let loss = Int(Double(village.population) * 0.1)
        village.modifyPopulation(by: -loss)

        // Major happiness penalty
        village.modifyHappiness(by: -30)

        print("💀 \(village.name): STARVATION! Lost \(loss) population")
    }

    // MARK: - Happiness Management
    func processHappiness(for villages: inout [Village]) {
        for i in 0..<villages.count {
            var village = villages[i]

            // Reset to base happiness
            var baseHappiness = 50

            // Building bonuses are calculated in totalHappiness

            // Food situation
            let foodNeeded = village.population
            let currentFood = village.resources[.food] ?? 0

            if currentFood < foodNeeded {
                baseHappiness -= 20 // Starvation penalty
            }

            village.happiness = baseHappiness
            villages[i] = village
        }
    }

    // MARK: - Tax Collection
    func collectTaxes(for villages: inout [Village]) {
        for i in 0..<villages.count {
            var village = villages[i]

            // Base tax: 0.5 gold per population
            let taxRate = 0.5
            let taxIncome = Int(Double(village.population) * taxRate)

            // Add gold resource
            village.add(.gold, amount: taxIncome)

            print("💰 \(village.name): Collected \(taxIncome) gold in taxes")

            villages[i] = village
        }
    }
}
