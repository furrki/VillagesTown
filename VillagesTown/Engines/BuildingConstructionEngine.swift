//
//  BuildingConstructionEngine.swift
//  VillagesTown
//
//  Created by Claude Code
//

import Foundation

class BuildingConstructionEngine {

    // MARK: - Building Construction
    func canBuild(building: Building, in village: Village) -> (can: Bool, reason: String) {
        // Check if village has space
        if !village.canBuildMore {
            return (false, "Village is full. Upgrade village level for more space.")
        }

        // Check if building already exists
        if village.buildings.contains(where: { $0.name == building.name }) {
            return (false, "This building already exists in this village.")
        }

        // Check resources
        for (resource, amount) in building.baseCost {
            let available = village.resources[resource] ?? 0
            if available < amount {
                return (false, "Not enough \(resource.name). Need \(amount), have \(available).")
            }
        }

        // Special requirements
        if building.name == "Fishery" {
            // Check if village is on coast
            // For now, we'll skip this check - can be enhanced later
        }

        return (true, "Can build")
    }

    func buildBuilding(building: Building, in village: inout Village) -> Bool {
        let check = canBuild(building: building, in: village)

        guard check.can else {
            print("❌ \(village.name): Cannot build \(building.name) - \(check.reason)")
            return false
        }

        // Pay costs
        for (resource, amount) in building.baseCost {
            _ = village.substract(resource, amount: amount)
        }

        // Add building
        village.addBuilding(building)

        print("🏗️ \(village.name): Built \(building.name)!")
        return true
    }

    // MARK: - Village Upgrade
    func canUpgradeVillage(_ village: Village) -> (can: Bool, cost: [Resource: Int], reason: String) {
        let nextLevel: Village.Level?
        var cost: [Resource: Int] = [:]

        switch village.level {
        case .village:
            nextLevel = .town
            cost = [.gold: 500, .stone: 100, .wood: 150]
            if village.population < 200 {
                return (false, cost, "Need 200 population (currently \(village.population))")
            }

        case .town:
            nextLevel = .district
            cost = [.gold: 1000, .stone: 200, .wood: 250]
            if village.population < 500 {
                return (false, cost, "Need 500 population (currently \(village.population))")
            }

        case .district:
            nextLevel = .castle
            cost = [.gold: 2000, .stone: 400, .wood: 500]
            if village.population < 1000 {
                return (false, cost, "Need 1000 population (currently \(village.population))")
            }

        case .castle:
            nextLevel = .city
            cost = [.gold: 5000, .stone: 800, .wood: 1000]
            if village.population < 2000 {
                return (false, cost, "Need 2000 population (currently \(village.population))")
            }

        case .city:
            return (false, [:], "Already at maximum level")
        }

        // Check resources
        for (resource, amount) in cost {
            let available = village.resources[resource] ?? 0
            if available < amount {
                return (false, cost, "Not enough \(resource.name). Need \(amount), have \(available)")
            }
        }

        return (true, cost, "Can upgrade to \(nextLevel!.rawValue)")
    }

    func upgradeVillage(_ village: inout Village) -> Bool {
        let check = canUpgradeVillage(village)

        guard check.can else {
            print("❌ \(village.name): Cannot upgrade - \(check.reason)")
            return false
        }

        // Pay costs
        for (resource, amount) in check.cost {
            _ = village.substract(resource, amount: amount)
        }

        // Upgrade level
        let oldLevel = village.level
        switch village.level {
        case .village: village.level = .town
        case .town: village.level = .district
        case .district: village.level = .castle
        case .castle: village.level = .city
        case .city: break
        }

        print("⬆️ \(village.name): Upgraded from \(oldLevel.rawValue) to \(village.level.rawValue)!")
        return true
    }
}
