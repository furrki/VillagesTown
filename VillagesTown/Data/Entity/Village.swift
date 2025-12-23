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

    // GARRISON SYSTEM - non-movable defensive units that auto-recover
    var garrisonStrength: Int = 5  // Current garrison strength
    var garrisonMaxStrength: Int = 10  // Max garrison based on buildings
    var underSiege: Bool = false  // True if attacked this turn - prevents regen

    // MOBILIZATION CAP - limits recruits per turn
    var recruitsThisTurn: Int = 0

    // Computed max based on buildings
    var maxRecruitsPerTurn: Int {
        var cap = 3  // Base cap

        // Barracks increases cap
        if let barracks = buildings.first(where: { $0.name == "Barracks" }) {
            cap += barracks.level  // +1 per barracks level
        }

        // Archery Range also helps
        if buildings.contains(where: { $0.name == "Archery Range" }) {
            cap += 1
        }

        return cap
    }

    init(name: String, nationality: Nationality, coordinates: CGPoint, owner: String) {
        self.name = name
        self.nationality = nationality
        self.coordinates = coordinates
        self.owner = owner
        self.buildings = Building.starter()

        // Initialize starting resources - GENEROUS for better gameplay
        self.resources = [
            .food: 100,
            .wood: 100,
            .iron: 50,
            .gold: 300
        ]

        // Neutral villages have less resources but more garrison
        if owner == "neutral" {
            self.resources = [
                .food: 20,
                .wood: 15,
                .iron: 5,
                .gold: 30
            ]
            self.garrisonStrength = 8
            self.garrisonMaxStrength = 15
            self.population = 50
        }
    }

    // MARK: - Computed Properties

    var maxBuildings: Int {
        switch level {
        case .village: return 8
        case .town: return 12
        case .district: return 16
        case .castle: return 20
        case .city: return 30
        }
    }

    var productionBonus: Double {
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

    // MARK: - Garrison Methods

    var computedGarrisonMax: Int {
        var maxGarrison = 10 // Base garrison

        // Barracks increases garrison
        if buildings.contains(where: { $0.name == "Barracks" }) {
            let barracksLevel = buildings.first(where: { $0.name == "Barracks" })?.level ?? 1
            maxGarrison += 5 * barracksLevel
        }

        // Fortress greatly increases garrison
        if buildings.contains(where: { $0.name == "Fortress" }) {
            let fortressLevel = buildings.first(where: { $0.name == "Fortress" })?.level ?? 1
            maxGarrison += 15 * fortressLevel
        }

        // Level bonus
        switch level {
        case .village: break
        case .town: maxGarrison += 5
        case .district: maxGarrison += 10
        case .castle: maxGarrison += 20
        case .city: maxGarrison += 30
        }

        return maxGarrison
    }

    mutating func regenerateGarrison() {
        // NO regeneration if under siege!
        if underSiege {
            underSiege = false  // Reset for next turn
            return
        }

        // Garrison recovers 1-3 per turn based on buildings
        var recovery = 1

        if buildings.contains(where: { $0.name == "Barracks" }) {
            recovery += 1
        }
        if buildings.contains(where: { $0.name == "Fortress" }) {
            recovery += 2
        }

        garrisonMaxStrength = computedGarrisonMax
        garrisonStrength = min(garrisonStrength + recovery, garrisonMaxStrength)
    }

    mutating func damageGarrison(amount: Int) {
        garrisonStrength = max(0, garrisonStrength - amount)
    }
}
