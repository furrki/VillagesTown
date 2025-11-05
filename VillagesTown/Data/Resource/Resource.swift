//
//  Resource.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 10.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import SwiftUI

enum Resource: Hashable {
    // Primary Resources
    case food
    case wood
    case iron
    case gold
    case stone
    case horses

    // Strategic Resources
    case gems
    case saltpeter
    case fish
    case wine

    var name: String {
        switch self {
        case .food: return "Food"
        case .wood: return "Wood"
        case .iron: return "Iron"
        case .gold: return "Gold"
        case .stone: return "Stone"
        case .horses: return "Horses"
        case .gems: return "Gems"
        case .saltpeter: return "Saltpeter"
        case .fish: return "Fish"
        case .wine: return "Wine"
        }
    }

    var emoji: String {
        switch self {
        case .food: return "🌾"
        case .wood: return "🪵"
        case .iron: return "⚔️"
        case .gold: return "💰"
        case .stone: return "🪨"
        case .horses: return "🐴"
        case .gems: return "💎"
        case .saltpeter: return "⚗️"
        case .fish: return "🐟"
        case .wine: return "🍷"
        }
    }

    var group: Group {
        switch self {
        case .food, .wood, .iron, .stone, .horses, .fish:
            return .raw
        case .gold:
            return .currency
        case .gems, .saltpeter, .wine:
            return .strategic
        }
    }

    var color: Color {
        switch self {
        case .food: return Color(red: 0.9, green: 0.8, blue: 0.3)
        case .wood: return Color(red: 0.6, green: 0.4, blue: 0.2)
        case .iron: return .gray
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .stone: return Color(red: 0.5, green: 0.5, blue: 0.5)
        case .horses: return Color(red: 0.6, green: 0.4, blue: 0.3)
        case .gems: return Color(red: 0.4, green: 0.8, blue: 1.0)
        case .saltpeter: return Color(red: 0.9, green: 0.9, blue: 0.9)
        case .fish: return Color(red: 0.3, green: 0.6, blue: 0.9)
        case .wine: return Color(red: 0.6, green: 0.1, blue: 0.3)
        }
    }
    
    // MARK: - Hashable
    static func == (lhs: Resource, rhs: Resource) -> Bool {
        lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name.hashValue)
    }
    
    // MARK: - Enums
    enum Group {
        case raw
        case processed
        case currency
        case strategic
    }

    // MARK: - Static Methods
    static func getAll() -> [Resource] {
        return [.food, .wood, .iron, .gold, .stone, .horses]
    }

    static func getAllStrategic() -> [Resource] {
        return [.gems, .saltpeter, .fish, .wine]
    }
}
