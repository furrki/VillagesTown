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

    let turnEngine: TurnEngine = TurnEngine()

    // Tutorial settings
    var tutorialEnabled: Bool = true
    var tutorialStep: Int = 0

    // MARK: - Initializers
    init() {
        // Create 50x50 map
        let mapSize = CGSize(width: 50.0, height: 50.0)

        // Create villages for each player
        let nationalities = Nationality.getAll()

        // Player villages (Turkish) - 4 villages
        let playerVillages = [
            Village(name: "Argithan", nationality: nationalities[0], coordinates: CGPoint(x: 10, y: 10), owner: "player"),
            Village(name: "Zafer", nationality: nationalities[0], coordinates: CGPoint(x: 15, y: 12), owner: "player"),
            Village(name: "Selim", nationality: nationalities[0], coordinates: CGPoint(x: 12, y: 15), owner: "player"),
            Village(name: "Orhan", nationality: nationalities[0], coordinates: CGPoint(x: 8, y: 13), owner: "player")
        ]

        // AI 1 villages (Greek) - 4 villages
        let ai1Villages = [
            Village(name: "Athens", nationality: nationalities[1], coordinates: CGPoint(x: 35, y: 10), owner: "ai1"),
            Village(name: "Sparta", nationality: nationalities[1], coordinates: CGPoint(x: 40, y: 12), owner: "ai1"),
            Village(name: "Corinth", nationality: nationalities[1], coordinates: CGPoint(x: 37, y: 15), owner: "ai1"),
            Village(name: "Thebes", nationality: nationalities[1], coordinates: CGPoint(x: 33, y: 13), owner: "ai1")
        ]

        // AI 2 villages (Bulgarian) - 4 villages
        let ai2Villages = [
            Village(name: "Sofia", nationality: nationalities[2], coordinates: CGPoint(x: 25, y: 35), owner: "ai2"),
            Village(name: "Plovdiv", nationality: nationalities[2], coordinates: CGPoint(x: 28, y: 38), owner: "ai2"),
            Village(name: "Varna", nationality: nationalities[2], coordinates: CGPoint(x: 22, y: 37), owner: "ai2"),
            Village(name: "Burgas", nationality: nationalities[2], coordinates: CGPoint(x: 26, y: 40), owner: "ai2")
        ]

        let allVillages = playerVillages + ai1Villages + ai2Villages

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
        print("🎮 Game Started! Turn \(currentTurn)")
        print("📍 Map size: \(Int(map.size.width))x\(Int(map.size.height))")
        print("🏘️ Total villages: \(map.villages.count)")
        print("👥 Players: \(players.count)")
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
