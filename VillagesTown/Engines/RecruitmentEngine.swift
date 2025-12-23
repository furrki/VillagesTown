//
//  RecruitmentEngine.swift
//  VillagesTown
//
//  Created by Claude Code
//

import Foundation

class RecruitmentEngine {

    // MARK: - Recruitment
    func canRecruit(unitType: Unit.UnitType, quantity: Int, in village: Village) -> (can: Bool, reason: String) {
        // Check if village has required military building
        let requiredBuilding = getRequiredBuilding(for: unitType)

        if !village.buildings.contains(where: { $0.name == requiredBuilding }) {
            return (false, "Requires \(requiredBuilding)")
        }

        // Check population for recruitment
        if village.population < quantity {
            return (false, "Not enough population. Need \(quantity), have \(village.population)")
        }

        // Get unit stats
        let stats = Unit.getStats(for: unitType)
        let totalCost = stats.cost.mapValues { $0 * quantity }

        // Check global resources
        let globalResources = GameManager.shared.getGlobalResources(playerID: village.owner)
        for (resource, amount) in totalCost {
            let available = globalResources[resource] ?? 0
            if available < amount {
                return (false, "Not enough \(resource.name). Need \(amount), have \(available)")
            }
        }

        return (true, "Can recruit")
    }

    func recruitUnits(unitType: Unit.UnitType, quantity: Int, in village: inout Village, at coordinates: CGPoint) -> [Unit] {
        let check = canRecruit(unitType: unitType, quantity: quantity, in: village)

        guard check.can else {
            print("❌ \(village.name): Cannot recruit \(unitType.rawValue) - \(check.reason)")
            return []
        }

        // Get unit stats and costs
        let stats = Unit.getStats(for: unitType)
        let totalCost = stats.cost.mapValues { $0 * quantity }

        // Pay costs from global pool
        guard GameManager.shared.spendResources(playerID: village.owner, cost: totalCost) else {
            print("❌ \(village.name): Failed to spend resources")
            return []
        }

        // Reduce population
        village.modifyPopulation(by: -quantity)

        // Create units
        var units: [Unit] = []
        for _ in 0..<quantity {
            let unit = Unit(type: unitType, owner: village.owner, coordinates: coordinates)
            units.append(unit)
        }

        // Add to existing army at village or create new one
        let game = GameManager.shared
        let existingArmies = game.getArmiesAt(villageID: village.id).filter { $0.owner == village.owner }

        if var army = existingArmies.first {
            army.addUnits(units)
            army.name = Army.generateName(for: army.units, owner: village.owner)
            game.updateArmy(army)
        } else {
            _ = game.createArmy(units: units, stationedAt: village.id, owner: village.owner)
        }

        print("⚔️ \(village.name): Recruited \(quantity) \(stats.name)!")
        return units
    }

    func getRequiredBuilding(for unitType: Unit.UnitType) -> String {
        switch unitType.category {
        case "Infantry":
            return "Barracks"
        case "Ranged":
            return "Archery Range"
        default:
            return "Barracks"
        }
    }

    func getAvailableUnits(for village: Village) -> [Unit.UnitType] {
        var available: [Unit.UnitType] = []

        // Check which military buildings exist
        let hasBarracks = village.buildings.contains(where: { $0.name == "Barracks" })
        let hasArcheryRange = village.buildings.contains(where: { $0.name == "Archery Range" })

        // Infantry
        if hasBarracks {
            available.append(contentsOf: [.militia, .spearman, .swordsman])
        }

        // Ranged
        if hasArcheryRange {
            available.append(contentsOf: [.archer, .crossbowman])
        }

        return available
    }
}
