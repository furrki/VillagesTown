//
//  UnitUpkeepEngine.swift
//  VillagesTown
//
//  Created by Claude Code
//

import Foundation

class UnitUpkeepEngine {

    func processUpkeep(units: [Unit], villages: inout [Village]) {
        // Group units by owner
        var unitsByOwner: [String: [Unit]] = [:]
        for unit in units {
            unitsByOwner[unit.owner, default: []].append(unit)
        }

        // Process upkeep for each owner
        for (owner, ownerUnits) in unitsByOwner {
            processUpkeepForOwner(owner: owner, units: ownerUnits, villages: &villages)
        }
    }

    private func processUpkeepForOwner(owner: String, units: [Unit], villages: inout [Village]) {
        // Calculate total upkeep
        var totalUpkeep: [Resource: Int] = [:]

        for unit in units {
            let stats = Unit.getStats(for: unit.unitType)
            for (resource, amount) in stats.upkeep {
                totalUpkeep[resource, default: 0] += amount
            }
        }

        // Try to pay from owner's villages
        let ownerVillages = villages.enumerated().filter { $1.owner == owner }

        if ownerVillages.isEmpty {
            return
        }

        // Calculate total resources available
        var totalAvailable: [Resource: Int] = [:]
        for (_, village) in ownerVillages {
            for (resource, amount) in village.resources {
                totalAvailable[resource, default: 0] += amount
            }
        }

        // Check if can afford upkeep
        var canAfford = true
        for (resource, needed) in totalUpkeep {
            if (totalAvailable[resource] ?? 0) < needed {
                canAfford = false
                break
            }
        }

        if canAfford {
            // Pay upkeep from villages (distribute across them)
            for (resource, totalAmount) in totalUpkeep {
                var remaining = totalAmount

                for (index, village) in ownerVillages {
                    if remaining <= 0 { break }

                    let available = villages[index].resources[resource] ?? 0
                    let toTake = min(available, remaining)

                    if toTake > 0 {
                        _ = villages[index].substract(resource, amount: toTake)
                        remaining -= toTake
                    }
                }
            }

            // Print upkeep summary
            var summary = "💸 \(owner) paid unit upkeep: "
            for (resource, amount) in totalUpkeep {
                summary += "\(resource.emoji)\(amount) "
            }
            print(summary)

        } else {
            // Cannot afford upkeep - units desert or lose morale
            print("⚠️ \(owner): Cannot afford unit upkeep! Units losing morale")
            // In a full implementation, units would desert or lose effectiveness
        }
    }
}
