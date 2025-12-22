//
//  Unit.swift
//  VillagesTown
//
//  Created by Claude Code
//

import SwiftUI

struct Unit: Entity, Identifiable {
    let id = UUID()
    let name: String
    let unitType: UnitType
    var attack: Int
    var defense: Int
    var maxHP: Int
    var currentHP: Int
    var movement: Int
    var movementRemaining: Int
    var level: Int = 1
    var experience: Int = 0
    var morale: Int = 100 // 0-100%
    var owner: String

    // Entity conformance
    var isMovable: Bool { return true }
    var coordinates: CGPoint
    var mapColor: Color {
        // Color based on owner
        return .blue
    }

    enum UnitType: String {
        // Infantry - Simplified to 3 types
        case militia
        case spearman
        case swordsman

        // Ranged - Simplified to 2 types
        case archer
        case crossbowman

        var category: String {
            switch self {
            case .militia, .spearman, .swordsman:
                return "Infantry"
            case .archer, .crossbowman:
                return "Ranged"
            }
        }

        var emoji: String {
            switch self {
            case .militia, .spearman, .swordsman:
                return "🗡️"
            case .archer, .crossbowman:
                return "🏹"
            }
        }
    }

    init(type: UnitType, owner: String, coordinates: CGPoint) {
        let stats = Unit.getStats(for: type)
        self.name = stats.name
        self.unitType = type
        self.attack = stats.attack
        self.defense = stats.defense
        self.maxHP = stats.hp
        self.currentHP = stats.hp
        self.movement = stats.movement
        self.movementRemaining = stats.movement
        self.owner = owner
        self.coordinates = coordinates
    }

    // MARK: - Unit Stats (Simplified)
    static func getStats(for type: UnitType) -> (name: String, attack: Int, defense: Int, hp: Int, movement: Int, cost: [Resource: Int], upkeep: [Resource: Int]) {
        switch type {
        // Infantry
        case .militia:
            return ("Militia", 5, 3, 50, 2, [.gold: 20, .food: 5], [.gold: 2, .food: 1])
        case .spearman:
            return ("Spearman", 8, 6, 70, 2, [.gold: 25, .iron: 5], [.gold: 2, .food: 1])
        case .swordsman:
            return ("Swordsman", 10, 7, 80, 2, [.gold: 30, .iron: 10], [.gold: 2, .food: 1])

        // Ranged
        case .archer:
            return ("Archer", 8, 4, 60, 2, [.gold: 40, .iron: 8], [.gold: 2, .food: 1])
        case .crossbowman:
            return ("Crossbowman", 12, 5, 70, 2, [.gold: 50, .iron: 12], [.gold: 2, .food: 1])
        }
    }

    // MARK: - Methods
    mutating func takeDamage(_ amount: Int) {
        currentHP = max(0, currentHP - amount)
    }

    mutating func heal(_ amount: Int) {
        currentHP = min(maxHP, currentHP + amount)
    }

    mutating func gainExperience(_ amount: Int) {
        experience += amount
        // Level up every 100 XP
        if experience >= level * 100 {
            levelUp()
        }
    }

    mutating func levelUp() {
        level += 1
        // +10% stats per level
        attack = Int(Double(attack) * 1.1)
        defense = Int(Double(defense) * 1.1)
        maxHP = Int(Double(maxHP) * 1.1)
        currentHP = maxHP
        print("⭐ \(name) leveled up to \(level)!")
    }

    mutating func resetMovement() {
        movementRemaining = movement
    }

    var isAlive: Bool {
        return currentHP > 0
    }
}
