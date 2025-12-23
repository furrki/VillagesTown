//
//  Army.swift
//  VillagesTown
//
//  Groups of units that travel together between villages
//

import Foundation

struct Army: Identifiable {
    let id = UUID()
    var name: String
    var units: [Unit]
    var owner: String

    // Current location (village ID or nil if traveling)
    var stationedAt: UUID?

    // Travel info
    var destination: UUID?
    var turnsUntilArrival: Int = 0
    var origin: UUID?

    // Computed properties
    var isMarching: Bool { destination != nil && turnsUntilArrival > 0 }

    var totalAttack: Int {
        units.reduce(0) { $0 + $1.attack }
    }

    var totalDefense: Int {
        units.reduce(0) { $0 + $1.defense }
    }

    var totalHP: Int {
        units.reduce(0) { $0 + $1.currentHP }
    }

    var strength: Int {
        // Combined measure for display
        totalAttack + totalDefense + (totalHP / 10)
    }

    var unitCount: Int { units.count }

    var primaryUnitType: Unit.UnitType? {
        // Most common unit type in army
        let counts = Dictionary(grouping: units, by: { $0.unitType })
        return counts.max(by: { $0.value.count < $1.value.count })?.key
    }

    var emoji: String {
        primaryUnitType?.emoji ?? "⚔️"
    }

    // MARK: - Methods

    mutating func addUnits(_ newUnits: [Unit]) {
        units.append(contentsOf: newUnits)
    }

    mutating func removeDeadUnits() {
        units.removeAll { !$0.isAlive }
    }

    mutating func marchTo(villageID: UUID, turns: Int, from originID: UUID?) {
        self.origin = originID ?? stationedAt
        self.stationedAt = nil
        self.destination = villageID
        self.turnsUntilArrival = turns
    }

    mutating func advanceMarch() {
        if turnsUntilArrival > 0 {
            turnsUntilArrival -= 1
        }
        if turnsUntilArrival == 0, let dest = destination {
            stationedAt = dest
            destination = nil
            origin = nil
        }
    }

    mutating func station(at villageID: UUID) {
        stationedAt = villageID
        destination = nil
        turnsUntilArrival = 0
        origin = nil
    }

    // Generate a name based on composition
    static func generateName(for units: [Unit], owner: String) -> String {
        let count = units.count
        let prefix = owner == "player" ? "" : "Enemy "

        if count <= 3 {
            return "\(prefix)Squad"
        } else if count <= 10 {
            return "\(prefix)Warband"
        } else if count <= 25 {
            return "\(prefix)Company"
        } else {
            return "\(prefix)Legion"
        }
    }
}

// Extension for calculating travel time between villages
extension Army {
    static func calculateTravelTime(from origin: CGPoint, to destination: CGPoint) -> Int {
        let dx = abs(destination.x - origin.x)
        let dy = abs(destination.y - origin.y)
        let distance = sqrt(dx * dx + dy * dy)

        // 1 turn per 5 tiles of distance, minimum 1 turn
        return max(1, Int(ceil(distance / 5.0)))
    }
}
