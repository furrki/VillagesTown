//
//  MovementEngine.swift
//  VillagesTown
//
//  Created by Claude Code
//

import Foundation
import CoreGraphics

class MovementEngine {

    // MARK: - Movement
    func canMoveTo(unit: Unit, destination: CGPoint, map: Map) -> (can: Bool, reason: String, cost: Int) {
        // Check if destination is within map bounds
        let width = Int(map.size.width)
        let height = Int(map.size.height)
        let destX = Int(destination.x)
        let destY = Int(destination.y)

        if destX < 0 || destY < 0 || destX >= width || destY >= height {
            return (false, "Destination out of bounds", 0)
        }

        // Calculate distance and movement cost
        let distance = calculateDistance(from: unit.coordinates, to: destination)

        if distance > 10 {
            return (false, "Too far away. Select closer destination.", 0)
        }

        // Get terrain cost
        var movementCost = 0
        if let virtualMap = map as? VirtualMap,
           let tile = virtualMap.getTile(at: destination) {
            movementCost = tile.terrain.movementCost
        } else {
            movementCost = 1
        }

        // Check if unit has enough movement
        if unit.movementRemaining < movementCost {
            return (false, "Not enough movement. Needs \(movementCost), has \(unit.movementRemaining).", movementCost)
        }

        return (true, "Can move", movementCost)
    }

    func moveUnit(unit: inout Unit, to destination: CGPoint, map: inout Map) -> Bool {
        let check = canMoveTo(unit: unit, destination: destination, map: map)

        guard check.can else {
            print("❌ Cannot move unit: \(check.reason)")
            return false
        }

        // Update unit position
        let oldPosition = unit.coordinates
        unit.coordinates = destination
        unit.movementRemaining -= check.cost

        // Update in map
        map.updateUnit(unit)

        print("🚶 Unit moved from (\(Int(oldPosition.x)), \(Int(oldPosition.y))) to (\(Int(destination.x)), \(Int(destination.y)))")
        return true
    }

    func resetMovement(for units: inout [Unit]) {
        for i in 0..<units.count {
            units[i].resetMovement()
        }
    }

    // MARK: - Helper Methods
    private func calculateDistance(from: CGPoint, to: CGPoint) -> Int {
        let dx = abs(Int(to.x) - Int(from.x))
        let dy = abs(Int(to.y) - Int(from.y))
        return max(dx, dy) // Chebyshev distance (diagonal movement)
    }
}
