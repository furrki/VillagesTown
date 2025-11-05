//
//  Tile.swift
//  VillagesTown
//
//  Created by Claude Code
//

import Foundation
import SwiftUI

struct Tile {
    let coordinates: CGPoint
    var terrain: Terrain
    var strategicResource: Resource?
    var explored: Bool = false
    var owner: String? // Village or faction name

    var isEmpty: Bool {
        return owner == nil
    }

    var movementCost: Int {
        return terrain.movementCost
    }

    var defenseBonus: Double {
        return terrain.defenseBonus
    }
}
