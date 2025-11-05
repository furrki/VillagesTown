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
        case pikeman
        case eliteGuard

        // Ranged
        case archer
        case crossbowman
        case longbowman

        // Cavalry
        case lightCavalry
        case heavyCavalry
        case cataphract

        // Siege
        case batteringRam
        case catapult
        case trebuchet

        // Naval
        case galley
        case warGalley

        var category: String {
            switch self {
            case .militia, .spearman, .swordsman, .pikeman, .eliteGuard:
                return "Infantry"
            case .archer, .crossbowman, .longbowman:
                return "Ranged"
            case .lightCavalry, .heavyCavalry, .cataphract:
                return "Cavalry"
            case .batteringRam, .catapult, .trebuchet:
                return "Siege"
            case .galley, .warGalley:
                return "Naval"
            }
        }

        var emoji: String {
            switch self {
            case .militia, .spearman, .swordsman, .pikeman, .eliteGuard:
                return "🗡️"
            case .archer, .crossbowman, .longbowman:
                return "🏹"
            case .lightCavalry, .heavyCavalry, .cataphract:
                return "🐎"
            case .batteringRam, .catapult, .trebuchet:
                return "🎯"
            case .galley, .warGalley:
                return "⛵"
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
            return ("Spearman", 8, 6, 70, 2, [.gold: 25, .iron: 5], [.gold: 2, .food: 1])
        case .swordsman:
            return ("Swordsman", 10, 7, 80, 2, [.gold: 30, .iron: 10], [.gold: 2, .food: 1])
        case .pikeman:
            return ("Pikeman", 12, 10, 90, 2, [.gold: 35, .iron: 12], [.gold: 2, .food: 1])
        case .eliteGuard:
            return ("Elite Guard", 15, 12, 100, 2, [.gold: 50, .iron: 20], [.gold: 3, .food: 1])

        // Ranged
        case .archer:
            return ("Archer", 8, 4, 60, 2, [.gold: 40, .iron: 8], [.gold: 2, .food: 1])
        case .crossbowman:
            return ("Crossbowman", 12, 5, 70, 2, [.gold: 50, .iron: 12], [.gold: 2, .food: 1])
        case .longbowman:
            return ("Longbowman", 10, 6, 75, 2, [.gold: 45, .iron: 10], [.gold: 2, .food: 1])

        // Cavalry
        case .lightCavalry:
            return ("Light Cavalry", 12, 5, 80, 4, [.gold: 50, .iron: 10, .horses: 1], [.gold: 3, .food: 2])
        case .heavyCavalry:
            return ("Heavy Cavalry", 15, 8, 100, 3, [.gold: 60, .iron: 15, .horses: 1], [.gold: 3, .food: 2])
        case .cataphract:
            return ("Cataphract", 18, 10, 120, 3, [.gold: 80, .iron: 25, .horses: 1], [.gold: 4, .food: 2])

        // Siege
        case .batteringRam:
            return ("Battering Ram", 15, 5, 100, 1, [.gold: 80, .wood: 40], [.gold: 3, .food: 2])
        case .catapult:
            return ("Catapult", 20, 3, 80, 1, [.gold: 100, .wood: 50, .iron: 20], [.gold: 4, .food: 2])
        case .trebuchet:
            return ("Trebuchet", 25, 5, 120, 1, [.gold: 150, .wood: 80, .iron: 30], [.gold: 5, .food: 3])

        // Naval
        case .galley:
            return ("Galley", 10, 8, 100, 3, [.gold: 100, .wood: 60], [.gold: 3, .food: 2])
        case .warGalley:
            return ("War Galley", 15, 12, 150, 3, [.gold: 150, .wood: 100, .iron: 30], [.gold: 5, .food: 3])
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
