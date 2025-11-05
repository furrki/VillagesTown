//
//  Resource.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 10.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import SwiftUI

enum Resource: Hashable {
    // Simplified Resources - Only 4 essential types
    case food
    case wood
    case iron
    case gold

    var name: String {
        switch self {
        case .food: return "Food"
        case .wood: return "Wood"
        case .iron: return "Iron"
        case .gold: return "Gold"
        }
    }

    var emoji: String {
        switch self {
        case .food: return "🌾"
        case .wood: return "🪵"
        case .iron: return "⚔️"
        case .gold: return "💰"
        }
    }

    var group: Group {
        switch self {
        case .food, .wood, .iron:
            return .raw
        case .gold:
            return .currency
        }
    }

    var color: Color {
        switch self {
        case .food: return Color(red: 0.9, green: 0.8, blue: 0.3)
        case .wood: return Color(red: 0.6, green: 0.4, blue: 0.2)
        case .iron: return .gray
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
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
        return [.food, .wood, .iron, .gold]
    }
}
