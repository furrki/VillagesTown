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
        let globalResources = GameManager.shared.getGlobalResources(playerID: player.id)

        // Determine recruitment strategy based on global resources
        let shouldRecruit: Bool
        let aggressiveness: Int

        switch personality {
        case .aggressive:
            shouldRecruit = (globalResources[.gold] ?? 0) > 100
            aggressiveness = 3 // Recruit more units

        case .economic:
            shouldRecruit = (globalResources[.gold] ?? 0) > 500
            aggressiveness = 1 // Recruit fewer units

        case .balanced:
            shouldRecruit = (globalResources[.gold] ?? 0) > 300
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
                    // RecruitmentEngine now handles adding to armies internally
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

        // EARLY GAME PROTECTION: Don't attack before turn 12
        // This gives players time to build up defenses
        let gracePeriod: Int
        switch personality {
        case .aggressive: gracePeriod = 8
        case .economic: gracePeriod = 15
        case .balanced: gracePeriod = 12
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

        // Find enemy targets
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

            // Find nearest enemy
            var nearestEnemy: Village?
            var shortestDistance = Int.max

            for enemy in enemies {
                let distance = calculateDistance(from: stationedAt.coordinates, to: enemy.coordinates)
                if distance < shortestDistance {
                    shortestDistance = distance
                    nearestEnemy = enemy
                }
            }

            guard let target = nearestEnemy else { continue }

            // Get defender strength estimate (including village garrison)
            let defenderArmies = game.getArmiesAt(villageID: target.id).filter { $0.owner == target.owner }
            let defenderArmyStrength = defenderArmies.reduce(0) { $0 + $1.strength }

            // Villages have inherent garrison strength from population
            let garrisonStrength = target.population / 10  // 10 pop = 1 strength
            let villageDefenseBonus = Int(Double(garrisonStrength) * (1.0 + target.defenseBonus))
            let totalDefenderStrength = defenderArmyStrength + villageDefenseBonus

            let attackerStrength = army.strength

            // Decide if should attack based on personality
            // Now requires SIGNIFICANT advantage because of garrison
            let shouldAttack: Bool
            switch personality {
            case .aggressive:
                // Need 1.5x strength to attack (was 0.7x)
                shouldAttack = attackerStrength > 0 && Double(attackerStrength) > Double(totalDefenderStrength) * 1.5
            case .economic:
                // Need 2.5x strength to attack (was 1.5x)
                shouldAttack = attackerStrength > 0 && Double(attackerStrength) > Double(totalDefenderStrength) * 2.5
            case .balanced:
                // Need 2.0x strength to attack (was 1.1x)
                shouldAttack = attackerStrength > 0 && Double(attackerStrength) > Double(totalDefenderStrength) * 2.0
            }

            // Require larger army sizes before attacking
            let minArmySize: Int
            switch personality {
            case .aggressive: minArmySize = 5
            case .economic: minArmySize = 10
            case .balanced: minArmySize = 7
            }

            if shouldAttack && army.unitCount >= minArmySize {
                // Send army to attack!
                if game.sendArmy(armyID: army.id, to: target.id) {
                    print("      🚶 \(army.name) (\(army.unitCount) units) sent to attack \(target.name)")
                    print("         Attacker: \(attackerStrength) vs Defender: \(totalDefenderStrength) (includes garrison)")
                }
            }
        }
    }

    private func calculateDistance(from: CGPoint, to: CGPoint) -> Int {
        let dx = abs(Int(to.x) - Int(from.x))
        let dy = abs(Int(to.y) - Int(from.y))
        return max(dx, dy)
    }
}
