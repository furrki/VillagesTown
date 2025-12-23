//
//  Building.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 11.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import Foundation

struct Building: Identifiable {
    var id = UUID()

    enum BuildingType {
        case production
        case military
        case infrastructure
        case special
    }

    var type: BuildingType
    var name: String
    var baseCost: [Resource: Int]
    var level: Int = 1
    var resourcesProduction: [Resource: Int] = [:]
    var resourcesConsumption: [Resource: Int] = [:]
    var description: String
    var productionBonus: Double = 0.0
    var defenseBonus: Double = 0.0
    var happinessBonus: Int = 0
    var canRecruitUnits: Bool = false

    // MARK: - Building Definitions (Simplified)

    // Economic Buildings
    static let farm = Building(
        type: .production,
        name: "Farm",
        baseCost: [.gold: 50, .wood: 20],
        resourcesProduction: [.food: 10],
        description: "Produces food for your population"
    )

    static let lumberMill = Building(
        type: .production,
        name: "Lumber Mill",
        baseCost: [.gold: 40],
        resourcesProduction: [.wood: 8],
        description: "Produces wood for construction"
    )

    static let ironMine = Building(
        type: .production,
        name: "Iron Mine",
        baseCost: [.gold: 60, .wood: 10],
        resourcesProduction: [.iron: 5],
        description: "Produces iron for military units"
    )

    static let market = Building(
        type: .production,
        name: "Market",
        baseCost: [.gold: 100, .wood: 30],
        resourcesProduction: [.gold: 15],
        description: "Generates gold through trade"
    )

    // Military Buildings
    static let barracks = Building(
        type: .military,
        name: "Barracks",
        baseCost: [.gold: 150, .wood: 50, .iron: 20],
        description: "Enables recruitment of infantry units",
        canRecruitUnits: true
    )

    static let archeryRange = Building(
        type: .military,
        name: "Archery Range",
        baseCost: [.gold: 140, .wood: 60, .iron: 15],
        description: "Enables recruitment of ranged units",
        canRecruitUnits: true
    )

    static let stables = Building(
        type: .military,
        name: "Stables",
        baseCost: [.gold: 200, .wood: 80, .food: 30],
        description: "Enables recruitment of cavalry units",
        canRecruitUnits: true
    )

    static let fortress = Building(
        type: .military,
        name: "Fortress",
        baseCost: [.gold: 300, .wood: 100, .iron: 50],
        description: "Provides strong defensive bonus",
        defenseBonus: 0.5
    )

    // Infrastructure Buildings
    static let granary = Building(
        type: .infrastructure,
        name: "Granary",
        baseCost: [.gold: 80, .wood: 40],
        resourcesProduction: [.food: 5],
        description: "Increases food storage and production",
        productionBonus: 0.1
    )

    // Special Buildings
    static let temple = Building(
        type: .special,
        name: "Temple",
        baseCost: [.gold: 200, .wood: 60],
        description: "Increases happiness and culture",
        happinessBonus: 15
    )

    static let library = Building(
        type: .special,
        name: "Library",
        baseCost: [.gold: 150, .wood: 50],
        description: "Generates science points for research"
    )

    // MARK: - Static Methods
    static let allEconomic: [Building] = [
        farm, lumberMill, ironMine, market
    ]

    static let allMilitary: [Building] = [
        barracks, archeryRange, fortress
    ]

    static let allInfrastructure: [Building] = [
        granary
    ]

    static let allSpecial: [Building] = [
        temple, library
    ]

    static let all: [Building] = allEconomic + allMilitary + allInfrastructure + allSpecial

    static func starter() -> [Building] {
        return [farm, lumberMill, ironMine]
    }
}
