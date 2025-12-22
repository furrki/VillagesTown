//
//  AIEngine.swift
//  VillagesTown
//
//  Created by Claude Code
//

import Foundation
import CoreGraphics

class AIEngine {
    let buildingEngine = BuildingConstructionEngine()
    let recruitmentEngine = RecruitmentEngine()
    let movementEngine = MovementEngine()
    let combatEngine = CombatEngine()

    // MARK: - AI Turn
    func executeAITurn(for player: Player, map: inout Map) {
        print("\n🤖 AI Turn: \(player.name) (\(player.aiPersonality?.description ?? "Unknown"))")

        guard !player.isHuman else { return }

        // Get AI villages
        var villages = map.villages.filter { $0.owner == player.id }

        if villages.isEmpty {
            print("   No villages remaining")
            return
        }

        // 1. Economic Phase - Build buildings
        print("   💰 Economic Phase")
        for i in 0..<villages.count {
            makeEconomicDecisions(player: player, village: &villages[i])
        }

        // Update map villages
        for village in villages {
            if let index = map.villages.firstIndex(where: { $0.id == village.id }) {
                map.villages[index] = village
            }
        }

        // 2. Military Phase - Recruit units
        print("   ⚔️ Military Phase")
        villages = map.villages.filter { $0.owner == player.id }
        for i in 0..<villages.count {
            makeMilitaryDecisions(player: player, village: &villages[i], map: &map)
        }

        // Update map villages again
        for village in villages {
            if let index = map.villages.firstIndex(where: { $0.id == village.id }) {
                map.villages[index] = village
            }
        }

        // 3. Combat Phase - Move and attack
        print("   🎯 Combat Phase")
        executeCombatStrategy(player: player, map: &map)
    }

    // MARK: - Economic AI
    func makeEconomicDecisions(player: Player, village: inout Village) {
        guard village.canBuildMore else { return }

        let personality = player.aiPersonality ?? .balanced

        // Determine what to build based on personality
        var buildingPriorities: [Building] = []

        switch personality {
        case .aggressive:
            // Focus on military and resources for military
            buildingPriorities = [
                Building.ironMine,
                Building.barracks,
                Building.market,
                Building.archeryRange
            ]

        case .economic:
            // Focus on economy and infrastructure
            buildingPriorities = [
                Building.farm,
                Building.market,
                Building.lumberMill,
                Building.granary,
                Building.temple,
                Building.ironMine,
                Building.barracks
            ]

        case .balanced:
            // Mix of everything
            buildingPriorities = [
                Building.farm,
                Building.market,
                Building.ironMine,
                Building.barracks,
                Building.lumberMill,
                Building.archeryRange
            ]
        }

        // Try to build first affordable building
        for building in buildingPriorities {
            let check = buildingEngine.canBuild(building: building, in: village)
            if check.can {
                if buildingEngine.buildBuilding(building: building, in: &village) {
                    print("      🏗️ \(village.name): Built \(building.name)")
                    break
                }
            }
        }
    }

    // MARK: - Military AI
    func makeMilitaryDecisions(player: Player, village: inout Village, map: inout Map) {
        let personality = player.aiPersonality ?? .balanced

        // Determine recruitment strategy
        let shouldRecruit: Bool
        let aggressiveness: Int

        switch personality {
        case .aggressive:
            shouldRecruit = village.resources[.gold] ?? 0 > 100
            aggressiveness = 3 // Recruit more units

        case .economic:
            shouldRecruit = village.resources[.gold] ?? 0 > 500
            aggressiveness = 1 // Recruit fewer units

        case .balanced:
            shouldRecruit = village.resources[.gold] ?? 0 > 300
            aggressiveness = 2 // Moderate recruitment
        }

        guard shouldRecruit else { return }

        // Get available units
        let availableUnits = recruitmentEngine.getAvailableUnits(for: village)

        if availableUnits.isEmpty { return }

        // Choose best unit to recruit
        let unitPriorities: [Unit.UnitType]
        switch personality {
        case .aggressive:
            unitPriorities = [.swordsman, .archer, .militia]
        case .economic:
            unitPriorities = [.spearman, .archer, .militia]
        case .balanced:
            unitPriorities = [.swordsman, .archer, .militia]
        }

        // Try to recruit
        for unitType in unitPriorities {
            if availableUnits.contains(unitType) {
                let quantity = min(aggressiveness, village.population / 10)
                let check = recruitmentEngine.canRecruit(unitType: unitType, quantity: quantity, in: village)

                if check.can {
                    let units = recruitmentEngine.recruitUnits(
                        unitType: unitType,
                        quantity: quantity,
                        in: &village,
                        at: village.coordinates
                    )

                    if !units.isEmpty {
                        map.addUnits(units)
                        print("      ⚔️ \(village.name): Recruited \(quantity) \(unitType.rawValue)")
                        break
                    }
                }
            }
        }
    }

    // MARK: - Combat AI
    func executeCombatStrategy(player: Player, map: inout Map) {
        let personality = player.aiPersonality ?? .balanced

        // Get AI units
        let aiUnits = map.units.filter { $0.owner == player.id }

        if aiUnits.isEmpty { return }

        // Find enemy targets
        let enemies = map.villages.filter { $0.owner != player.id }

        if enemies.isEmpty { return }

        // For each unit stack
        let unitPositions = Dictionary(grouping: aiUnits) { $0.coordinates }

        for (position, units) in unitPositions {
            // Find nearest enemy
            var nearestEnemy: Village?
            var shortestDistance = Int.max

            for enemy in enemies {
                let distance = calculateDistance(from: position, to: enemy.coordinates)
                if distance < shortestDistance {
                    shortestDistance = distance
                    nearestEnemy = enemy
                }
            }

            guard let target = nearestEnemy else { continue }

            // Decide whether to attack or move closer
            let adjacentDistance = 1

            if shortestDistance <= adjacentDistance {
                // Attack if adjacent
                attemptAttack(attackers: units, target: target, map: &map, personality: personality)
            } else {
                // Move closer
                moveTowardsTarget(units: units, target: target.coordinates, map: &map)
            }
        }
    }

    // MARK: - Combat Helpers
    private func attemptAttack(attackers: [Unit], target: Village, map: inout Map, personality: Player.AIPersonality) {
        // Get defenders at target
        let defenders = map.units.filter { $0.coordinates == target.coordinates && $0.owner != attackers.first?.owner }

        // Calculate strength advantage
        let attackerStrength = attackers.reduce(0) { $0 + $1.attack }
        let defenderStrength = defenders.reduce(0) { $0 + $1.defense }

        // Decide if should attack based on personality
        let shouldAttack: Bool
        switch personality {
        case .aggressive:
            shouldAttack = Double(attackerStrength) > Double(defenderStrength) * 0.7 // Attack even when slightly weaker
        case .economic:
            shouldAttack = Double(attackerStrength) > Double(defenderStrength) * 1.5 // Only attack when much stronger
        case .balanced:
            shouldAttack = Double(attackerStrength) > Double(defenderStrength) * 1.1 // Attack when stronger
        }

        if shouldAttack && !defenders.isEmpty {
            print("      ⚔️ Attacking \(target.name) with \(attackers.count) units")

            var mutableAttackers = attackers
            var mutableDefenders = defenders

            let result = combatEngine.resolveCombat(
                attackers: &mutableAttackers,
                defenders: &mutableDefenders,
                location: target.coordinates,
                map: map,
                defendingVillage: target
            )

            // Update units on map
            for attacker in attackers {
                map.removeUnit(attacker)
            }
            for defender in defenders {
                map.removeUnit(defender)
            }

            for survivor in mutableAttackers {
                map.addUnit(survivor)
            }
            for survivor in mutableDefenders {
                map.addUnit(survivor)
            }

            // If attackers won and no defenders, conquer village
            if result.attackerWon && mutableDefenders.isEmpty {
                if var village = map.villages.first(where: { $0.id == target.id }) {
                    combatEngine.conquerVillage(village: &village, newOwner: attackers.first?.owner ?? "")
                    if let index = map.villages.firstIndex(where: { $0.id == village.id }) {
                        map.villages[index] = village
                    }
                }
            }
        }
    }

    private func moveTowardsTarget(units: [Unit], target: CGPoint, map: inout Map) {
        for unit in units {
            guard var mutableUnit = map.units.first(where: { $0.id == unit.id }) else { continue }

            if mutableUnit.movementRemaining <= 0 { continue }

            // Calculate direction to target
            let dx = target.x - mutableUnit.coordinates.x
            let dy = target.y - mutableUnit.coordinates.y

            // Move one step towards target
            var newX = mutableUnit.coordinates.x
            var newY = mutableUnit.coordinates.y

            if abs(dx) > abs(dy) {
                newX += dx > 0 ? 1 : -1
            } else {
                newY += dy > 0 ? 1 : -1
            }

            let newPosition = CGPoint(x: newX, y: newY)

            // Try to move
            if movementEngine.moveUnit(unit: &mutableUnit, to: newPosition, map: &map) {
                // Success - movement already logged
            }
        }
    }

    private func calculateDistance(from: CGPoint, to: CGPoint) -> Int {
        let dx = abs(Int(to.x) - Int(from.x))
        let dy = abs(Int(to.y) - Int(from.y))
        return max(dx, dy)
    }
}
