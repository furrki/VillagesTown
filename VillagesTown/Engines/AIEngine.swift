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
                Building.barracks,  // First priority - need to recruit
                Building.ironMine,
                Building.market,
                Building.archeryRange,
                Building.farm
            ]

        case .economic:
            // Focus on economy and infrastructure
            buildingPriorities = [
                Building.farm,
                Building.market,
                Building.lumberMill,
                Building.barracks,  // Still need military eventually
                Building.granary,
                Building.temple,
                Building.ironMine
            ]

        case .balanced:
            // Mix of everything
            buildingPriorities = [
                Building.barracks,  // Get military capability first
                Building.farm,
                Building.market,
                Building.ironMine,
                Building.lumberMill,
                Building.archeryRange
            ]
        }

        // Try to build first affordable building
        for building in buildingPriorities {
            // Skip if already have this building
            if village.buildings.contains(where: { $0.name == building.name }) {
                continue
            }

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
        let globalResources = GameManager.shared.getGlobalResources(playerID: player.id)

        // Check if village can recruit (has barracks)
        let availableUnits = recruitmentEngine.getAvailableUnits(for: village)
        if availableUnits.isEmpty {
            return // No barracks - can't recruit
        }

        // Determine recruitment strategy - be more aggressive about recruiting
        let goldThreshold: Int
        let recruitCount: Int

        switch personality {
        case .aggressive:
            goldThreshold = 50   // Recruit even with low gold
            recruitCount = 3     // Recruit more units
        case .economic:
            goldThreshold = 200
            recruitCount = 1
        case .balanced:
            goldThreshold = 100
            recruitCount = 2
        }

        guard (globalResources[.gold] ?? 0) > goldThreshold else { return }

        // Choose best unit to recruit
        let unitPriorities: [Unit.UnitType] = [.militia, .swordsman, .archer, .spearman]

        // Try to recruit
        for unitType in unitPriorities {
            if availableUnits.contains(unitType) {
                let quantity = recruitCount
                let check = recruitmentEngine.canRecruit(unitType: unitType, quantity: quantity, in: village)

                if check.can {
                    let units = recruitmentEngine.recruitUnits(
                        unitType: unitType,
                        quantity: quantity,
                        in: &village,
                        at: village.coordinates
                    )

                    if !units.isEmpty {
                        print("      ⚔️ \(village.name): Recruited \(quantity) \(unitType.rawValue)")
                        break
                    }
                }
            }
        }
    }

    // MARK: - Combat AI (Army-based)
    func executeCombatStrategy(player: Player, map: inout Map) {
        let personality = player.aiPersonality ?? .balanced
        let game = GameManager.shared

        // Shorter grace period
        let gracePeriod: Int
        switch personality {
        case .aggressive: gracePeriod = 5
        case .economic: gracePeriod = 10
        case .balanced: gracePeriod = 7
        }

        if game.currentTurn < gracePeriod {
            print("      [Grace period - no attacks until turn \(gracePeriod)]")
            return
        }

        // Get AI armies that are stationed (not marching)
        let stationedArmies = game.getStationedArmiesFor(playerID: player.id)

        if stationedArmies.isEmpty {
            print("      No stationed armies")
            return
        }

        // Find ALL potential targets (enemies and neutrals)
        let enemies = map.villages.filter { $0.owner != player.id }

        if enemies.isEmpty {
            print("      No enemy targets")
            return
        }

        // For each stationed army, decide whether to send it
        for army in stationedArmies {
            guard let stationedAtID = army.stationedAt,
                  let stationedAt = map.villages.first(where: { $0.id == stationedAtID }) else {
                continue
            }

            // Find the WEAKEST target, not nearest (smarter AI)
            var bestTarget: Village?
            var bestTargetScore = Int.min // Higher = better target

            for enemy in enemies {
                // Calculate enemy strength
                let defenderArmies = game.getArmiesAt(villageID: enemy.id).filter { $0.owner == enemy.owner }
                let defenderArmyStrength = defenderArmies.reduce(0) { $0 + $1.strength }
                let garrisonStrength = enemy.garrisonStrength * 3
                let totalDefenderStrength = defenderArmyStrength + garrisonStrength

                // Calculate distance penalty
                let distance = calculateDistance(from: stationedAt.coordinates, to: enemy.coordinates)

                // Score = our advantage - distance penalty
                // Higher score = easier target
                let advantage = army.strength - totalDefenderStrength
                let score = advantage - (distance * 5)  // Penalize far targets

                // Bonus for neutral villages (easier)
                let neutralBonus = enemy.owner == "neutral" ? 50 : 0

                let finalScore = score + neutralBonus

                if finalScore > bestTargetScore {
                    bestTargetScore = finalScore
                    bestTarget = enemy
                }
            }

            guard let target = bestTarget else { continue }

            // Calculate if we can win
            let defenderArmies = game.getArmiesAt(villageID: target.id).filter { $0.owner == target.owner }
            let defenderArmyStrength = defenderArmies.reduce(0) { $0 + $1.strength }
            let garrisonStrength = target.garrisonStrength * 3
            let totalDefenderStrength = defenderArmyStrength + garrisonStrength

            let attackerStrength = army.strength

            // Much more aggressive attack thresholds
            let shouldAttack: Bool
            switch personality {
            case .aggressive:
                // Attack if we have 80% of defender strength
                shouldAttack = attackerStrength > 0 && Double(attackerStrength) > Double(totalDefenderStrength) * 0.8
            case .economic:
                // Need 1.5x strength
                shouldAttack = attackerStrength > 0 && Double(attackerStrength) > Double(totalDefenderStrength) * 1.5
            case .balanced:
                // Need equal strength
                shouldAttack = attackerStrength > 0 && Double(attackerStrength) >= Double(totalDefenderStrength) * 1.0
            }

            // Lower minimum army size
            let minArmySize: Int
            switch personality {
            case .aggressive: minArmySize = 3
            case .economic: minArmySize = 5
            case .balanced: minArmySize = 4
            }

            // Special case: always attack undefended neutrals
            let isUndefendedNeutral = target.owner == "neutral" && defenderArmyStrength == 0 && target.garrisonStrength < 5

            if (shouldAttack && army.unitCount >= minArmySize) || (isUndefendedNeutral && army.unitCount >= 2) {
                // Send army to attack!
                if game.sendArmy(armyID: army.id, to: target.id) {
                    print("      🚶 \(army.name) (\(army.unitCount) units, str:\(attackerStrength)) → \(target.name) (def:\(totalDefenderStrength))")
                }
            } else {
                print("      ⏳ \(army.name) waiting (str:\(attackerStrength) vs \(totalDefenderStrength))")
            }
        }
    }

    private func calculateDistance(from: CGPoint, to: CGPoint) -> Int {
        let dx = abs(Int(to.x) - Int(from.x))
        let dy = abs(Int(to.y) - Int(from.y))
        return max(dx, dy)
    }
}
