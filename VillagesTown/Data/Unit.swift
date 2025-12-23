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
        // Infantry
        case militia
        case spearman
        case swordsman

        // Ranged
        case archer
        case crossbowman

        // Cavalry
        case lightCavalry
        case knight

        var category: String {
            switch self {
            case .militia, .spearman, .swordsman:
                return "Infantry"
            case .archer, .crossbowman:
                return "Ranged"
            case .lightCavalry, .knight:
                return "Cavalry"
            }
        }

        var emoji: String {
            switch self {
            case .militia: return "🗡️"
            case .spearman: return "🛡️"
            case .swordsman: return "⚔️"
            case .archer: return "🏹"
            case .crossbowman: return "🎯"
            case .lightCavalry: return "🐴"
            case .knight: return "🐎"
            }
        }

        // UNIT COUNTER SYSTEM
        // Returns damage multiplier against target type
        func damageMultiplier(against target: UnitType) -> Double {
            switch self {
            // Spearmen are STRONG vs Cavalry
            case .spearman:
                if target.category == "Cavalry" { return 1.5 }

            // Cavalry STRONG vs Ranged, WEAK vs Spearmen
            case .lightCavalry, .knight:
                if target.category == "Ranged" { return 1.5 }
                if target == .spearman { return 0.6 }

            // Archers STRONG vs Infantry (except shields)
            case .archer, .crossbowman:
                if target == .militia { return 1.3 }
                if target == .swordsman { return 1.2 }

            // Swordsmen balanced, slight bonus vs militia
            case .swordsman:
                if target == .militia { return 1.2 }

            default:
                break
            }
            return 1.0  // No modifier
        }

        // Text description of counters
        var counterInfo: String {
            switch self {
            case .spearman: return "Strong vs Cavalry"
            case .lightCavalry, .knight: return "Strong vs Ranged"
            case .archer, .crossbowman: return "Strong vs Infantry"
            case .swordsman: return "Balanced fighter"
            case .militia: return "Cheap, weak"
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

    // MARK: - Unit Stats
    static func getStats(for type: UnitType) -> (name: String, attack: Int, defense: Int, hp: Int, movement: Int, cost: [Resource: Int], upkeep: [Resource: Int]) {
        switch type {
        // Infantry
        case .militia:
            return ("Militia", 5, 3, 50, 2, [.gold: 20, .food: 5], [.gold: 2, .food: 1])
        case .spearman:
            return ("Spearman", 7, 8, 70, 2, [.gold: 30, .iron: 5], [.gold: 2, .food: 1])  // High defense, anti-cav
        case .swordsman:
            return ("Swordsman", 10, 6, 80, 2, [.gold: 35, .iron: 10], [.gold: 2, .food: 1])

        // Ranged
        case .archer:
            return ("Archer", 9, 3, 50, 2, [.gold: 35, .wood: 10], [.gold: 2, .food: 1])  // High attack, fragile
        case .crossbowman:
            return ("Crossbowman", 12, 4, 60, 2, [.gold: 50, .iron: 10], [.gold: 3, .food: 1])

        // Cavalry - Fast, expensive, strong but countered by spears
        case .lightCavalry:
            return ("Light Cavalry", 9, 5, 70, 4, [.gold: 60, .food: 15], [.gold: 4, .food: 2])
        case .knight:
            return ("Knight", 14, 8, 100, 3, [.gold: 100, .iron: 20], [.gold: 6, .food: 2])
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
