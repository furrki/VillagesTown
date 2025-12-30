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
    @Published var ai1Nationality: Nationality?
    @Published var ai2Nationality: Nationality?

    let turnEngine: TurnEngine = TurnEngine()

    // Global resource pools per player
    @Published var globalResources: [String: [Resource: Int]] = [:]

    // Army system
    @Published var armies: [Army] = []

    // Turn events for summary
    @Published var turnEvents: [TurnEvent] = []

    // FOG OF WAR - tracks what player has discovered
    @Published var discoveredVillageIDs: Set<UUID> = []
    let visionRange: CGFloat = 8.0  // How far you can see from your villages/armies

    // Tutorial settings
    var tutorialEnabled: Bool = true
    var tutorialStep: Int = 0

    // MARK: - Initializers
    init() {
        // Create 20x20 map
        let mapSize = CGSize(width: 20.0, height: 20.0)

        // Placeholder villages - will be regenerated when player picks nationality
        self.map = VirtualMap(size: mapSize, villages: [])
        self.players = Player.createPlayers()
    }

    func setupGame(playerNationality: Nationality) {
        self.playerNationality = playerNationality
        let nationalities = Nationality.getAll()

        // Find AI nationalities (excluding player's choice)
        let aiNationalities = nationalities.filter { $0.name != playerNationality.name }.shuffled()

        // Store AI nationalities for reference
        self.ai1Nationality = aiNationalities[0]
        self.ai2Nationality = aiNationalities.count > 1 ? aiNationalities[1] : aiNationalities[0]

        // Player village - named after their nationality
        let playerVillage = Village(
            name: getCapitalName(for: playerNationality),
            nationality: playerNationality,
            coordinates: CGPoint(x: 3, y: 3),
            owner: "player"
        )

        let ai1Village = Village(
            name: getCapitalName(for: self.ai1Nationality!),
            nationality: self.ai1Nationality!,
            coordinates: CGPoint(x: 17, y: 3),
            owner: "ai1"
        )

        let ai2Village = Village(
            name: getCapitalName(for: self.ai2Nationality!),
            nationality: self.ai2Nationality!,
            coordinates: CGPoint(x: 10, y: 17),
            owner: "ai2"
        )

        // NEUTRAL VILLAGES - more settlements spread across the map
        let neutralVillages = [
            // Northern region
            Village(name: "Thessaloniki", nationality: nationalities[1], coordinates: CGPoint(x: 10, y: 2), owner: "neutral"),
            Village(name: "Alexandroupoli", nationality: nationalities[1], coordinates: CGPoint(x: 14, y: 4), owner: "neutral"),
            // Western region
            Village(name: "Kavala", nationality: nationalities[1], coordinates: CGPoint(x: 2, y: 10), owner: "neutral"),
            Village(name: "Ioannina", nationality: nationalities[1], coordinates: CGPoint(x: 5, y: 7), owner: "neutral"),
            // Central region
            Village(name: "Edirne", nationality: nationalities[0], coordinates: CGPoint(x: 8, y: 8), owner: "neutral"),
            Village(name: "Bursa", nationality: nationalities[0], coordinates: CGPoint(x: 12, y: 10), owner: "neutral"),
            Village(name: "Plovdiv", nationality: nationalities[2], coordinates: CGPoint(x: 10, y: 13), owner: "neutral"),
            // Eastern region
            Village(name: "Varna", nationality: nationalities[2], coordinates: CGPoint(x: 18, y: 8), owner: "neutral"),
            Village(name: "Constanta", nationality: nationalities[2], coordinates: CGPoint(x: 16, y: 14), owner: "neutral"),
            // Southern region
            Village(name: "Izmir", nationality: nationalities[0], coordinates: CGPoint(x: 6, y: 15), owner: "neutral"),
            Village(name: "Antalya", nationality: nationalities[0], coordinates: CGPoint(x: 14, y: 18), owner: "neutral"),
            Village(name: "Patras", nationality: nationalities[1], coordinates: CGPoint(x: 2, y: 17), owner: "neutral")
        ]

        let allVillages = [playerVillage, ai1Village, ai2Village] + neutralVillages

        // Create map with all villages
        self.map = VirtualMap(size: CGSize(width: 20, height: 20), villages: allVillages)

        // Update player village lists
        for i in 0..<self.players.count {
            let playerID = self.players[i].id
            self.players[i].villages = allVillages.filter { $0.owner == playerID }.map { $0.name }
        }

        print("🗺️ Map created with \(allVillages.count) villages")
        print("   Player: \(playerVillage.name) (\(playerNationality.flag))")
        print("   AI1: \(ai1Village.name) (\(self.ai1Nationality!.flag))")
        print("   AI2: \(ai2Village.name) (\(self.ai2Nationality!.flag))")
        print("   Neutral: \(neutralVillages.count) villages")
    }

    private func getCapitalName(for nationality: Nationality) -> String {
        switch nationality.name {
        case "Turkish": return "Istanbul"
        case "Greek": return "Athens"
        case "Bulgarian": return "Sofia"
        default: return "Capital"
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

    func resetGame() {
        // Clear all game state
        gameStarted = false
        currentTurn = 0
        currentPlayer = "player"
        playerNationality = nil
        ai1Nationality = nil
        ai2Nationality = nil
        armies.removeAll()
        turnEvents.removeAll()
        globalResources.removeAll()
        discoveredVillageIDs.removeAll()  // Reset fog of war

        // Reset map
        map = VirtualMap(size: CGSize(width: 20, height: 20), villages: [])

        // Reset players
        players = Player.createPlayers()

        print("🔄 Game Reset!")
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

    // MARK: - Fog of War

    func isVillageVisible(village: Village, for playerID: String) -> Bool {
        // Your own villages are always visible
        if village.owner == playerID { return true }

        // Already discovered villages stay visible
        if discoveredVillageIDs.contains(village.id) { return true }

        // Check if within vision range of any player village
        let playerVillages = getPlayerVillages(playerID: playerID)
        for pv in playerVillages {
            let dist = distance(from: pv.coordinates, to: village.coordinates)
            if dist <= visionRange {
                discoveredVillageIDs.insert(village.id)
                return true
            }
        }

        // Check if within vision range of any player army
        let playerArmies = getArmiesFor(playerID: playerID)
        for army in playerArmies {
            if let stationedAt = army.stationedAt,
               let stationedVillage = map.villages.first(where: { $0.id == stationedAt }) {
                let dist = distance(from: stationedVillage.coordinates, to: village.coordinates)
                if dist <= visionRange {
                    discoveredVillageIDs.insert(village.id)
                    return true
                }
            }
        }

        return false
    }

    func isArmyVisible(army: Army, for playerID: String) -> Bool {
        // Your own armies always visible
        if army.owner == playerID { return true }

        // Get army location
        guard let locationID = army.stationedAt ?? army.destination,
              let locationVillage = map.villages.first(where: { $0.id == locationID }) else {
            return false
        }

        // Check vision from player villages
        let playerVillages = getPlayerVillages(playerID: playerID)
        for pv in playerVillages {
            let dist = distance(from: pv.coordinates, to: locationVillage.coordinates)
            if dist <= visionRange { return true }
        }

        // Check vision from player armies
        let playerArmies = getArmiesFor(playerID: playerID)
        for pa in playerArmies {
            if let paLocation = pa.stationedAt,
               let paVillage = map.villages.first(where: { $0.id == paLocation }) {
                let dist = distance(from: paVillage.coordinates, to: locationVillage.coordinates)
                if dist <= visionRange { return true }
            }
        }

        return false
    }

    private func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        sqrt(pow(to.x - from.x, 2) + pow(to.y - from.y, 2))
    }

    func getVisibleVillages(for playerID: String) -> [Village] {
        map.villages.filter { isVillageVisible(village: $0, for: playerID) }
    }

    func getVisibleArmies(for playerID: String) -> [Army] {
        armies.filter { isArmyVisible(army: $0, for: playerID) }
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
    case general(message: String)

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
        case .general(let m): return "general_\(m.hashValue)"
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
        case .general: return "ℹ️"
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
        case .general(let message):
            return message
        }
    }

    var isImportant: Bool {
        switch self {
        case .villageConquered, .villageLost, .enemyApproaching, .general:
            return true
        default:
            return false
        }
    }
}
