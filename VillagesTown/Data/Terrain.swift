//
//  Terrain.swift
//  VillagesTown
//
//  Created by Claude Code
//

import SwiftUI

enum Terrain: String, CaseIterable {
    case plains
    case forest
    case mountains
    case hills
    case river
    case coast

    var name: String {
        return rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .plains: return Color(red: 0.8, green: 0.9, blue: 0.6)
        case .forest: return Color(red: 0.2, green: 0.6, blue: 0.2)
        case .mountains: return Color(red: 0.5, green: 0.4, blue: 0.3)
        case .hills: return Color(red: 0.7, green: 0.7, blue: 0.5)
        case .river: return Color(red: 0.3, green: 0.5, blue: 0.9)
        case .coast: return Color(red: 0.4, green: 0.6, blue: 0.95)
        }
    }

    var movementCost: Int {
        switch self {
        case .plains: return 1
        case .forest: return 2
        case .mountains: return 3
        case .hills: return 2
        case .river: return 2
        case .coast: return 1
        }
    }

    var defenseBonus: Double {
        switch self {
        case .plains: return 0.0
        case .forest: return 0.2
        case .mountains: return 0.4
        case .hills: return 0.15
        case .river: return 0.1
        case .coast: return 0.0
        }
    }

    var canBuildOn: Bool {
        switch self {
        case .river, .coast: return false
        default: return true
        }
    }
}
