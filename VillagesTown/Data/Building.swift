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

    // MARK: - Building Definitions

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

    static let quarry = Building(
        type: .production,
        name: "Quarry",
        baseCost: [.gold: 50, .wood: 15],
        resourcesProduction: [.stone: 6],
        description: "Produces stone for fortifications"
    )

    static let stable = Building(
        type: .production,
        name: "Stable",
        baseCost: [.gold: 80, .wood: 30],
        resourcesProduction: [.horses: 3],
        description: "Breeds horses for cavalry units"
    )

    static let market = Building(
        type: .production,
        name: "Market",
        baseCost: [.gold: 100, .wood: 30],
        resourcesProduction: [.gold: 15],
        description: "Generates gold through trade"
    )

    static let fishery = Building(
        type: .production,
        name: "Fishery",
        baseCost: [.gold: 60, .wood: 25],
        resourcesProduction: [.food: 8, .fish: 2],
        description: "Produces food and fish (requires coast)"
    )

    static let winery = Building(
        type: .production,
        name: "Winery",
        baseCost: [.gold: 120, .wood: 40],
        resourcesProduction: [.wine: 3, .gold: 10],
        description: "Produces wine luxury resource",
        happinessBonus: 5
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

    static let cavalryStable = Building(
        type: .military,
        name: "Cavalry Stable",
        baseCost: [.gold: 200, .wood: 80, .iron: 30, .horses: 10],
        description: "Enables recruitment of cavalry units",
        canRecruitUnits: true
    )

    static let siegeWorkshop = Building(
        type: .military,
        name: "Siege Workshop",
        baseCost: [.gold: 250, .wood: 100, .iron: 50],
        description: "Enables construction of siege weapons",
        canRecruitUnits: true
    )

    static let fortress = Building(
        type: .military,
        name: "Fortress",
        baseCost: [.gold: 300, .wood: 100, .stone: 50],
        description: "Provides strong defensive bonus",
        defenseBonus: 0.5
    )

    static let watchtower = Building(
        type: .military,
        name: "Watchtower",
        baseCost: [.gold: 100, .wood: 40, .stone: 20],
        description: "Increases vision and early warning",
        defenseBonus: 0.15
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

    static let aqueduct = Building(
        type: .infrastructure,
        name: "Aqueduct",
        baseCost: [.gold: 150, .stone: 50],
        description: "Increases population capacity by 50%",
        happinessBonus: 10
    )

    static let road = Building(
        type: .infrastructure,
        name: "Road Network",
        baseCost: [.gold: 100, .stone: 30],
        description: "Reduces movement cost in your territory"
    )

    // Special Buildings
    static let temple = Building(
        type: .special,
        name: "Temple",
        baseCost: [.gold: 200, .stone: 60],
        description: "Increases happiness and generates culture",
        happinessBonus: 15
    )

    static let library = Building(
        type: .special,
        name: "Library",
        baseCost: [.gold: 150, .wood: 50],
        description: "Generates science points for research"
    )

    static let university = Building(
        type: .special,
        name: "University",
        baseCost: [.gold: 300, .stone: 80],
        description: "Advanced research facility"
    )

    static let monument = Building(
        type: .special,
        name: "Monument",
        baseCost: [.gold: 250, .stone: 100],
        description: "Generates culture and prestige",
        happinessBonus: 20
    )

    static let tavern = Building(
        type: .special,
        name: "Tavern",
        baseCost: [.gold: 120, .wood: 40],
        description: "Increases happiness and enables spy recruitment",
        happinessBonus: 10
    )

    static let hospital = Building(
        type: .special,
        name: "Hospital",
        baseCost: [.gold: 180, .wood: 50, .stone: 30],
        description: "Increases population growth rate",
        happinessBonus: 5
    )

    // MARK: - Static Methods
    static let allEconomic: [Building] = [
        farm, lumberMill, ironMine, quarry, stable, market, fishery, winery
    ]

    static let allMilitary: [Building] = [
        barracks, archeryRange, cavalryStable, siegeWorkshop, fortress, watchtower
    ]

    static let allInfrastructure: [Building] = [
        granary, aqueduct, road
    ]

    static let allSpecial: [Building] = [
        temple, library, university, monument, tavern, hospital
    ]

    static let all: [Building] = allEconomic + allMilitary + allInfrastructure + allSpecial

    static func starter() -> [Building] {
        return [farm, lumberMill, ironMine]
    }
}
