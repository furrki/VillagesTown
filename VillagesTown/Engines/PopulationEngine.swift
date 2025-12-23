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

            // Check food availability (1 food per 20 population - reduced requirement)
            let foodNeeded = max(1, village.population / 20)
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
        // MUCH higher base growth: 5% + flat bonus
        var growthRate = 0.05
        var flatBonus = 3  // Always grow by at least 3

        // Happiness bonus
        let happiness = village.totalHappiness
        if happiness >= 80 {
            growthRate += 0.03  // +3% if very happy
            flatBonus += 2
        } else if happiness >= 60 {
            growthRate += 0.01  // +1% if happy
            flatBonus += 1
        } else if happiness < 40 {
            growthRate -= 0.02  // -2% if unhappy
            flatBonus = 1
        }

        // Farm bonus - each farm adds growth
        let farmCount = village.buildings.filter { $0.name == "Farm" }.count
        flatBonus += farmCount * 2

        // Granary bonus
        if village.buildings.contains(where: { $0.name == "Granary" }) {
            growthRate += 0.02
        }

        // Check if at capacity
        if village.population >= village.populationCapacity {
            growthRate = 0
            flatBonus = 0
        }

        let percentGrowth = Int(Double(village.population) * growthRate)
        let totalGrowth = max(0, percentGrowth + flatBonus)

        if totalGrowth > 0 {
            village.modifyPopulation(by: totalGrowth)
            print("📈 \(village.name): +\(totalGrowth) pop (now \(village.population))")
        }
    }

    private func starvePopulation(village: inout Village) {
        // Starvation causes 5% population loss (reduced from 10%)
        let loss = max(1, Int(Double(village.population) * 0.05))
        village.modifyPopulation(by: -loss)

        // Happiness penalty
        village.modifyHappiness(by: -15)

        print("💀 \(village.name): STARVATION! Lost \(loss) population")
    }

    // MARK: - Happiness Management
    func processHappiness(for villages: inout [Village]) {
        for i in 0..<villages.count {
            var village = villages[i]

            // Start with decent base happiness
            var baseHappiness = 60

            // Food situation
            let foodNeeded = max(1, village.population / 20)
            let currentFood = village.resources[.food] ?? 0

            if currentFood >= foodNeeded * 2 {
                baseHappiness += 10  // Surplus food = happy
            } else if currentFood < foodNeeded {
                baseHappiness -= 25  // Starvation penalty
            }

            // Population density penalty if overcrowded
            if village.population > village.populationCapacity * 80 / 100 {
                baseHappiness -= 10
            }

            village.happiness = min(100, max(0, baseHappiness))
            villages[i] = village
        }
    }

    // MARK: - Tax Collection
    func collectTaxes(for villages: inout [Village]) {
        for i in 0..<villages.count {
            var village = villages[i]

            // Better tax: 1 gold per population
            let taxRate = 1.0
            let taxIncome = Int(Double(village.population) * taxRate)

            // Market bonus
            if village.buildings.contains(where: { $0.name == "Market" }) {
                let bonus = taxIncome / 4  // +25% with market
                village.add(.gold, amount: taxIncome + bonus)
                print("💰 \(village.name): +\(taxIncome + bonus) gold (market bonus)")
            } else {
                village.add(.gold, amount: taxIncome)
                print("💰 \(village.name): +\(taxIncome) gold")
            }

            villages[i] = village
        }
    }
}
