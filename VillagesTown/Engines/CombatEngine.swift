//
//  CombatEngine.swift
//  VillagesTown
//
//  Created by Claude Code
//

import Foundation
import CoreGraphics

struct CombatResult {
    let attackerWon: Bool
    let attackerCasualties: Int
    let defenderCasualties: Int
    let damage: Int
    let experienceGained: Int
}

class CombatEngine {

    // MARK: - Combat
    func canAttack(attacker: [Unit], defender: [Unit], at location: CGPoint, map: Map) -> (can: Bool, reason: String) {
        if attacker.isEmpty {
            return (false, "No attacking units")
        }

        if defender.isEmpty {
            return (false, "No defending units")
        }

        // Check if attacker has movement remaining
        if !attacker.contains(where: { $0.movementRemaining > 0 }) {
            return (false, "No units have movement remaining")
        }

        return (true, "Can attack")
    }

    func resolveCombat(attackers: inout [Unit], defenders: inout [Unit], location: CGPoint, map: Map, defendingVillage: Village?) -> CombatResult {
        print("\n⚔️ BATTLE at (\(Int(location.x)), \(Int(location.y)))")
        print("Attackers: \(attackers.count) units")
        print("Defenders: \(defenders.count) units")

        // Calculate total strength
        let attackerStrength = calculateArmyStrength(units: attackers, isAttacking: true, location: location, map: map, village: nil)
        let defenderStrength = calculateArmyStrength(units: defenders, isAttacking: false, location: location, map: map, village: defendingVillage)

        print("💪 Attacker strength: \(attackerStrength)")
        print("🛡️ Defender strength: \(defenderStrength)")

        // Battle resolution
        var attackerHP = attackers.reduce(0) { $0 + $1.currentHP }
        var defenderHP = defenders.reduce(0) { $0 + $1.currentHP }

        var rounds = 0
        let maxRounds = 10

        while attackerHP > 0 && defenderHP > 0 && rounds < maxRounds {
            rounds += 1

            // Attacker deals damage
            let attackerDamage = Int(Double(attackerStrength) * (1.0 + Double.random(in: 0...0.2)))
            defenderHP -= attackerDamage

            if defenderHP <= 0 { break }

            // Defender deals damage
            let defenderDamage = Int(Double(defenderStrength) * (1.0 + Double.random(in: 0...0.2)))
            attackerHP -= defenderDamage
        }

        // Determine winner
        let attackerWon = attackerHP > 0 || (attackerHP == defenderHP && attackerHP > 0)

        // Calculate casualties
        let attackerCasualties = calculateCasualties(units: &attackers, remainingHP: attackerHP)
        let defenderCasualties = calculateCasualties(units: &defenders, remainingHP: defenderHP)

        // Experience gain
        let experienceGained = 50 + defenderCasualties * 10

        if attackerWon {
            print("✅ Attackers WIN! Lost \(attackerCasualties) units, killed \(defenderCasualties)")
            for i in 0..<attackers.count {
                attackers[i].gainExperience(experienceGained)
            }
        } else {
            print("❌ Defenders WIN! Lost \(defenderCasualties) units, killed \(attackerCasualties)")
            for i in 0..<defenders.count {
                defenders[i].gainExperience(experienceGained)
            }
        }

        return CombatResult(
            attackerWon: attackerWon,
            attackerCasualties: attackerCasualties,
            defenderCasualties: defenderCasualties,
            damage: attackerWon ? defenderHP : attackerHP,
            experienceGained: experienceGained
        )
    }

    // MARK: - Strength Calculation
    private func calculateArmyStrength(units: [Unit], isAttacking: Bool, location: CGPoint, map: Map, village: Village?) -> Int {
        var totalStrength = 0

        for unit in units {
            var strength = isAttacking ? unit.attack : unit.defense

            // Terrain modifier
            if !isAttacking, let virtualMap = map as? VirtualMap,
               let tile = virtualMap.getTile(at: location) {
                let terrainBonus = tile.terrain.defenseBonus
                strength = Int(Double(strength) * (1.0 + terrainBonus))
            }

            // Village defense bonus
            if let village = village, !isAttacking {
                strength = Int(Double(strength) * (1.0 + village.defenseBonus))
            }

            // Morale modifier
            let moraleModifier = Double(unit.morale) / 100.0
            strength = Int(Double(strength) * moraleModifier)

            // Level bonus
            let levelBonus = 1.0 + (Double(unit.level - 1) * 0.1)
            strength = Int(Double(strength) * levelBonus)

            // HP factor (wounded units fight worse)
            let hpFactor = Double(unit.currentHP) / Double(unit.maxHP)
            strength = Int(Double(strength) * hpFactor)

            totalStrength += strength
        }

        return totalStrength
    }

    // MARK: - Casualties
    private func calculateCasualties(units: inout [Unit], remainingHP: Int) -> Int {
        var totalHP = units.reduce(0) { $0 + $1.currentHP }
        var hpLost = totalHP - max(0, remainingHP)
        var casualties = 0

        // Distribute damage
        for i in 0..<units.count {
            if hpLost <= 0 { break }

            let damage = min(units[i].currentHP, hpLost)
            units[i].takeDamage(damage)
            hpLost -= damage

            if units[i].currentHP <= 0 {
                casualties += 1
            }
        }

        // Remove dead units
        units.removeAll(where: { $0.currentHP <= 0 })

        return casualties
    }

    // MARK: - Village Conquest
    func conquerVillage(village: inout Village, newOwner: String) {
        let oldOwner = village.owner
        village.owner = newOwner

        // Population loss from conquest
        let populationLoss = Int(Double(village.population) * 0.3)
        village.modifyPopulation(by: -populationLoss)

        // Happiness penalty
        village.modifyHappiness(by: -30)

        print("🏴 \(village.name) conquered! New owner: \(newOwner)")
        print("💔 Population loss: \(populationLoss)")
        print("😔 Happiness decreased by 30")
    }
}
