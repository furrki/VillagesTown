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

    // Army system
    @Published var armies: [Army] = []

    // Turn events for summary
    @Published var turnEvents: [TurnEvent] = []

    // Tutorial settings
    var tutorialEnabled: Bool = true
    var tutorialStep: Int = 0

    // MARK: - Initializers
    init() {
        // Create 20x20 map (smaller for better UX)
        let mapSize = CGSize(width: 20.0, height: 20.0)

        // Each player starts with 1 village
        let nationalities = Nationality.getAll()

        let playerVillages = [
            Village(name: "Argithan", nationality: nationalities[0], coordinates: CGPoint(x: 3, y: 3), owner: "player")
        ]

        let ai1Villages = [
            Village(name: "Athens", nationality: nationalities[1], coordinates: CGPoint(x: 16, y: 3), owner: "ai1")
        ]

        let ai2Villages = [
            Village(name: "Sofia", nationality: nationalities[2], coordinates: CGPoint(x: 10, y: 16), owner: "ai2")
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

        // Initialize global resource pools by aggregating village resources
        syncGlobalResources()

        // Give each player a starting army for defense
        createStartingArmies()

        print("🎮 Game Started! Turn \(currentTurn)")
        print("📍 Map size: \(Int(map.size.width))x\(Int(map.size.height))")
        print("🏘️ Total villages: \(map.villages.count)")
        print("👥 Players: \(players.count)")
        print("⚔️ Starting armies created: \(armies.count)")
    }

    private func createStartingArmies() {
        // Each village gets a small starting garrison
        for village in map.villages {
            // Create 3 militia for each starting village
            var startingUnits: [Unit] = []
            for _ in 0..<3 {
                let militia = Unit(type: .militia, owner: village.owner, coordinates: village.coordinates)
                startingUnits.append(militia)
            }

            createArmy(units: startingUnits, stationedAt: village.id, owner: village.owner)
            print("🛡️ Created starting garrison at \(village.name)")
        }
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

    // MARK: - Army Management

    func getArmiesAt(villageID: UUID) -> [Army] {
        armies.filter { $0.stationedAt == villageID }
    }

    func getArmiesFor(playerID: String) -> [Army] {
        armies.filter { $0.owner == playerID }
    }

    func getMarchingArmiesFor(playerID: String) -> [Army] {
        armies.filter { $0.owner == playerID && $0.isMarching }
    }

    func getStationedArmiesFor(playerID: String) -> [Army] {
        armies.filter { $0.owner == playerID && !$0.isMarching }
    }

    @discardableResult
    func createArmy(units: [Unit], stationedAt villageID: UUID, owner: String) -> Army {
        let army = Army(
            name: Army.generateName(for: units, owner: owner),
            units: units,
            owner: owner,
            stationedAt: villageID
        )
        armies.append(army)
        return army
    }

    func updateArmy(_ army: Army) {
        if let index = armies.firstIndex(where: { $0.id == army.id }) {
            armies[index] = army
        }
    }

    func removeArmy(_ armyID: UUID) {
        armies.removeAll { $0.id == armyID }
    }

    func mergeArmiesAt(villageID: UUID, owner: String) {
        let armiesHere = armies.filter { $0.stationedAt == villageID && $0.owner == owner }
        guard armiesHere.count > 1 else { return }

        var allUnits: [Unit] = []
        for army in armiesHere {
            allUnits.append(contentsOf: army.units)
            removeArmy(army.id)
        }

        _ = createArmy(units: allUnits, stationedAt: villageID, owner: owner)
    }

    func sendArmy(armyID: UUID, to destinationVillageID: UUID) -> Bool {
        guard let index = armies.firstIndex(where: { $0.id == armyID }),
              let destination = map.villages.first(where: { $0.id == destinationVillageID }),
              let origin = armies[index].stationedAt,
              let originVillage = map.villages.first(where: { $0.id == origin }) else {
            return false
        }

        let turns = Army.calculateTravelTime(
            from: originVillage.coordinates,
            to: destination.coordinates
        )

        armies[index].marchTo(villageID: destinationVillageID, turns: turns, from: origin)

        addTurnEvent(.armySent(
            armyName: armies[index].name,
            destination: destination.name,
            turns: turns
        ))

        return true
    }

    // Convert legacy units to armies at game start
    func convertUnitsToArmies() {
        // Group units by location and owner
        var unitsByLocation: [String: [Unit]] = [:]

        for unit in map.units {
            let key = "\(unit.owner)_\(Int(unit.coordinates.x))_\(Int(unit.coordinates.y))"
            unitsByLocation[key, default: []].append(unit)
        }

        // Create armies for each group
        for (_, units) in unitsByLocation {
            guard let firstUnit = units.first,
                  let village = map.getVillageAt(x: Int(firstUnit.coordinates.x), y: Int(firstUnit.coordinates.y)) else {
                continue
            }
            _ = createArmy(units: units, stationedAt: village.id, owner: firstUnit.owner)
        }

        // Clear legacy unit array
        map.units.removeAll()
    }

    // MARK: - Turn Events

    func addTurnEvent(_ event: TurnEvent) {
        turnEvents.append(event)
    }

    func clearTurnEvents() {
        turnEvents.removeAll()
    }
}

// MARK: - Turn Event

enum TurnEvent: Identifiable {
    case resourceGain(resource: Resource, amount: Int)
    case armySent(armyName: String, destination: String, turns: Int)
    case armyArrived(armyName: String, destination: String)
    case battleWon(location: String, casualties: Int)
    case battleLost(location: String, casualties: Int)
    case villageConquered(villageName: String)
    case villageLost(villageName: String)
    case enemyApproaching(enemyName: String, target: String, turns: Int)

    var id: String {
        switch self {
        case .resourceGain(let r, let a): return "res_\(r.name)_\(a)"
        case .armySent(let n, let d, _): return "sent_\(n)_\(d)"
        case .armyArrived(let n, let d): return "arrived_\(n)_\(d)"
        case .battleWon(let l, _): return "won_\(l)"
        case .battleLost(let l, _): return "lost_\(l)"
        case .villageConquered(let v): return "conquered_\(v)"
        case .villageLost(let v): return "lost_v_\(v)"
        case .enemyApproaching(let e, let t, _): return "enemy_\(e)_\(t)"
        }
    }

    var emoji: String {
        switch self {
        case .resourceGain: return "📦"
        case .armySent: return "🚶"
        case .armyArrived: return "🏁"
        case .battleWon: return "⚔️"
        case .battleLost: return "💀"
        case .villageConquered: return "🎉"
        case .villageLost: return "😢"
        case .enemyApproaching: return "⚠️"
        }
    }

    var message: String {
        switch self {
        case .resourceGain(let resource, let amount):
            return "+\(amount) \(resource.emoji) \(resource.name)"
        case .armySent(let name, let dest, let turns):
            return "\(name) marching to \(dest) (\(turns) turns)"
        case .armyArrived(let name, let dest):
            return "\(name) arrived at \(dest)"
        case .battleWon(let location, let casualties):
            return "Victory at \(location)! Lost \(casualties) units"
        case .battleLost(let location, let casualties):
            return "Defeat at \(location). Lost \(casualties) units"
        case .villageConquered(let name):
            return "\(name) conquered!"
        case .villageLost(let name):
            return "\(name) was lost!"
        case .enemyApproaching(let enemy, let target, let turns):
            return "⚠️ \(enemy) approaching \(target)! \(turns) turns away"
        }
    }

    var isImportant: Bool {
        switch self {
        case .villageConquered, .villageLost, .enemyApproaching:
            return true
        default:
            return false
        }
    }
}
