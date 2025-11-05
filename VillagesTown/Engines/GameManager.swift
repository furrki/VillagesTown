//
//  GameManager.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 10.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import Foundation

class GameManager: ObservableObject {
    static let shared: GameManager = GameManager()

    // MARK: - Properties
    @Published var map: Map
    @Published var players: [Player]
    @Published var currentTurn: Int = 0
    @Published var currentPlayer: String = "player"
    @Published var gameStarted: Bool = false
    @Published var playerNationality: Nationality?

    let turnEngine: TurnEngine = TurnEngine()

    // Global resource pools per player
    @Published var globalResources: [String: [Resource: Int]] = [:]

    // Tutorial settings
    var tutorialEnabled: Bool = true
    var tutorialStep: Int = 0

    // MARK: - Initializers
    init() {
        // Create 50x50 map
        let mapSize = CGSize(width: 50.0, height: 50.0)

        // Create villages for each player
        let nationalities = Nationality.getAll()

        // Player villages - START WITH 1 VILLAGE
        let playerVillages = [
            Village(name: "Argithan", nationality: nationalities[0], coordinates: CGPoint(x: 10, y: 10), owner: "player")
        ]

        // AI 1 villages (Greek) - 1 village
        let ai1Villages = [
            Village(name: "Athens", nationality: nationalities[1], coordinates: CGPoint(x: 35, y: 10), owner: "ai1")
        ]

        let allVillages = playerVillages + ai1Villages

        // Create map
        self.map = VirtualMap(size: mapSize, villages: allVillages)

        // Create players
        self.players = Player.createPlayers()

        // Update player village lists
        for i in 0..<self.players.count {
            let playerID = self.players[i].id
            self.players[i].villages = allVillages.filter { $0.owner == playerID }.map { $0.name }
        }
    }

    func initializeGame() {
        gameStarted = true
        currentTurn = 1

        // Initialize global resource pools by aggregating village resources
        syncGlobalResources()

        print("🎮 Game Started! Turn \(currentTurn)")
        print("📍 Map size: \(Int(map.size.width))x\(Int(map.size.height))")
        print("🏘️ Total villages: \(map.villages.count)")
        print("👥 Players: \(players.count)")
    }

    // MARK: - Resource Management
    func syncGlobalResources() {
        // Aggregate all village resources into global pools
        for player in players {
            let villages = getPlayerVillages(playerID: player.id)
            var totalResources: [Resource: Int] = [:]

            for village in villages {
                for (resource, amount) in village.resources {
                    totalResources[resource, default: 0] += amount
                }
            }

            globalResources[player.id] = totalResources
        }
    }

    func getGlobalResources(playerID: String) -> [Resource: Int] {
        return globalResources[playerID] ?? [:]
    }

    func modifyGlobalResource(playerID: String, resource: Resource, amount: Int) {
        globalResources[playerID, default: [:]][resource, default: 0] += amount
        if globalResources[playerID]![resource]! < 0 {
            globalResources[playerID]![resource] = 0
        }
    }

    func canAfford(playerID: String, cost: [Resource: Int]) -> Bool {
        let resources = getGlobalResources(playerID: playerID)
        for (resource, amount) in cost {
            if (resources[resource] ?? 0) < amount {
                return false
            }
        }
        return true
    }

    func spendResources(playerID: String, cost: [Resource: Int]) -> Bool {
        guard canAfford(playerID: playerID, cost: cost) else {
            return false
        }

        for (resource, amount) in cost {
            modifyGlobalResource(playerID: playerID, resource: resource, amount: -amount)
        }
        return true
    }

    // MARK: - Tutorial Methods
    func toggleTutorial() {
        tutorialEnabled.toggle()
        print(tutorialEnabled ? "✅ Tutorial Enabled" : "❌ Tutorial Disabled")
    }

    func nextTutorialStep() {
        tutorialStep += 1
    }

    func skipTutorial() {
        tutorialEnabled = false
        tutorialStep = 999
    }

    // MARK: - Game Methods
    func getPlayerVillages(playerID: String) -> [Village] {
        return map.villages.filter { $0.owner == playerID }
    }

    func getVillage(named name: String) -> Village? {
        return map.villages.first(where: { $0.name == name })
    }

    func updateVillage(_ village: Village) {
        if let index = map.villages.firstIndex(where: { $0.id == village.id }) {
            map.villages[index] = village
        }
    }
}
