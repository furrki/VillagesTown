//
//  Map.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 10.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import CoreGraphics

protocol Map {
    var size: CGSize { get }
    var villages: [Village] { get set }
    var tiles: [[Tile]] { get set }
    var units: [Unit] { get set }
}

class VirtualMap: Map {
    let size: CGSize
    var villages: [Village] = []
    var tiles: [[Tile]] = []
    var units: [Unit] = []

    init(size: CGSize, villages: [Village] = []) {
        self.size = size
        self.villages = villages
        self.tiles = VirtualMap.generateTerrain(width: Int(size.width), height: Int(size.height))
        self.placeStrategicResources()
    }

    // MARK: - Terrain Generation
    static func generateTerrain(width: Int, height: Int) -> [[Tile]] {
        var tiles: [[Tile]] = []

        for y in 0..<height {
            var row: [Tile] = []
            for x in 0..<width {
                let terrain = randomTerrain(x: x, y: y, width: width, height: height)
                let tile = Tile(coordinates: CGPoint(x: x, y: y), terrain: terrain)
                row.append(tile)
            }
            tiles.append(row)
        }

        return tiles
    }

    static func randomTerrain(x: Int, y: Int, width: Int, height: Int) -> Terrain {
        // Create varied terrain based on position
        let random = Int.random(in: 0...100)

        // Edges more likely to be water/coast
        if x == 0 || y == 0 || x == width - 1 || y == height - 1 {
            return random < 70 ? .coast : .plains
        }

        // Create some structure
        switch random {
        case 0...50: return .plains
        case 51...70: return .forest
        case 71...80: return .hills
        case 81...90: return .mountains
        case 91...95: return .river
        default: return .plains
        }
    }

    func placeStrategicResources() {
        let strategicResources = [Resource.iron, Resource.gold]
        let width = Int(size.width)
        let height = Int(size.height)

        // Place 8-12 strategic resources randomly
        let resourceCount = Int.random(in: 8...12)

        for _ in 0..<resourceCount {
            let x = Int.random(in: 5..<width-5)
            let y = Int.random(in: 5..<height-5)
            let resource = strategicResources.randomElement()!

            tiles[y][x].strategicResource = resource
        }
    }

    func getTile(at point: CGPoint) -> Tile? {
        let x = Int(point.x)
        let y = Int(point.y)
        guard x >= 0, y >= 0, x < Int(size.width), y < Int(size.height) else {
            return nil
        }
        return tiles[y][x]
    }

    func updateTile(at point: CGPoint, tile: Tile) {
        let x = Int(point.x)
        let y = Int(point.y)
        guard x >= 0, y >= 0, x < Int(size.width), y < Int(size.height) else {
            return
        }
        tiles[y][x] = tile
    }
}

extension Map {
    var entities: [Entity] {
        return [villages as [Entity], units as [Entity]].flatMap { $0 }
    }

    func getEntityAt(x: Int, y: Int) -> Entity? {
        return entities.first(where: { $0.coordinates.x == CGFloat(x) && $0.coordinates.y == CGFloat(y) })
    }

    func getVillageAt(x: Int, y: Int) -> Village? {
        return villages.first(where: { $0.coordinates.x == CGFloat(x) && $0.coordinates.y == CGFloat(y) })
    }

    func getUnitsAt(x: Int, y: Int) -> [Unit] {
        return units.filter { $0.coordinates.x == CGFloat(x) && $0.coordinates.y == CGFloat(y) }
    }

    func getUnitsAt(point: CGPoint) -> [Unit] {
        return units.filter { $0.coordinates == point }
    }

    mutating func addUnit(_ unit: Unit) {
        units.append(unit)
    }

    mutating func addUnits(_ newUnits: [Unit]) {
        units.append(contentsOf: newUnits)
    }

    mutating func removeUnit(_ unit: Unit) {
        units.removeAll(where: { $0.id == unit.id })
    }

    mutating func updateUnit(_ unit: Unit) {
        if let index = units.firstIndex(where: { $0.id == unit.id }) {
            units[index] = unit
        }
    }

    func findEmptyAdjacentTile(to point: CGPoint) -> CGPoint {
        let x = Int(point.x)
        let y = Int(point.y)
        let width = Int(size.width)
        let height = Int(size.height)

        // Check all 8 adjacent tiles + the tile itself
        let adjacentOffsets = [
            (0, 0),   // Same tile (fallback)
            (1, 0), (-1, 0), (0, 1), (0, -1),  // Cardinal directions
            (1, 1), (-1, -1), (1, -1), (-1, 1)  // Diagonals
        ]

        for (dx, dy) in adjacentOffsets {
            let newX = x + dx
            let newY = y + dy

            // Check bounds
            guard newX >= 0, newY >= 0, newX < width, newY < height else { continue }

            let checkPoint = CGPoint(x: newX, y: newY)

            // Check if tile is empty (no village)
            if getVillageAt(x: newX, y: newY) == nil {
                return checkPoint
            }
        }

        // If no empty tile found, return original point
        return point
    }
}
