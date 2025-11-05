//
//  Village.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 10.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import SwiftUI

struct Village: Entity, ResourceHolder, TreasuryHolder {
    // MARK: - Properties
    let id = UUID()
    let name: String
    var mapColor: Color = .red
    let nationality: Nationality
    let isMovable: Bool = false
    var coordinates: CGPoint
    var level: Level = .village
    var buildings: [Building] = []
    var resources: [Resource : Int] = [:]
    var money: Double = Constants.villageStartCash
    var population: Int = Constants.villageStartPopulation
    var happiness: Int = 75 // 0-100%
    var owner: String // Player or AI faction identifier

    init(name: String, nationality: Nationality, coordinates: CGPoint, owner: String) {
        self.name = name
        self.nationality = nationality
        self.coordinates = coordinates
        self.owner = owner
        self.buildings = Building.starter()

        // Initialize starting resources
        self.resources = [
            .food: 50,
            .wood: 30,
            .iron: 10,
            .gold: 100,
            .stone: 10,
            .horses: 0
        ]
    }

    // MARK: - Computed Properties

    var maxBuildings: Int {
        switch level {
        case .village: return 3
        case .town: return 5
        case .district: return 7
        case .castle: return 10
        case .city: return 15
        }
    }

    var productionBonus: Double {
        let levelBonus: Double
        switch level {
        case .village: return 0.1
        case .town: return 0.2
        case .district: return 0.3
        case .castle: return 0.4
        case .city: return 0.5
        }
    }

    var defenseBonus: Double {
        var bonus = 0.2 // Base defense bonus for defending
        for building in buildings {
            bonus += building.defenseBonus
        }
        // Castle and City provide additional defense
        switch level {
        case .castle: bonus += 0.25
        case .city: bonus += 0.5
        default: break
        }
        return bonus
    }

    var totalHappiness: Int {
        var total = happiness
        for building in buildings {
            total += building.happinessBonus
        }
        // Cap at 100
        return min(total, 100)
    }

    var populationCapacity: Int {
        var capacity = 200
        switch level {
        case .village: capacity = 200
        case .town: capacity = 500
        case .district: capacity = 1000
        case .castle: capacity = 2000
        case .city: capacity = 5000
        }

        // Aqueduct increases capacity
        if buildings.contains(where: { $0.name == "Aqueduct" }) {
            capacity = Int(Double(capacity) * 1.5)
        }
        return capacity
    }

    var canBuildMore: Bool {
        return buildings.count < maxBuildings
    }

    // MARK: - Methods

    mutating func addBuilding(_ building: Building) {
        if canBuildMore {
            buildings.append(building)
        }
    }

    mutating func modifyPopulation(by amount: Int) {
        population = max(0, min(population + amount, populationCapacity))
    }

    mutating func modifyHappiness(by amount: Int) {
        happiness = max(0, min(happiness + amount, 100))
    }
}
