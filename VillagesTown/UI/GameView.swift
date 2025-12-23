//
//  GameView.swift
//  VillagesTown
//
//  Strategic game view with army-based gameplay
//

import SwiftUI

struct GameView: View {
    @ObservedObject var gameManager = GameManager.shared
    @State private var selectedVillage: Village?
    @State private var selectedArmy: Army?
    @State private var showTurnSummary = false
    @State private var showSendArmySheet = false
    @State private var isProcessingTurn = false

    var winner: Player? {
        let activePlayers = gameManager.players.filter { !$0.isEliminated }
        return activePlayers.count == 1 ? activePlayers.first : nil
    }

    var body: some View {
        ZStack {
            // Main game content
            HStack(spacing: 0) {
                // Left: Strategic Map
                VStack(spacing: 0) {
                    topBar
                    strategicMapView
                    bottomBar
                }
                .frame(maxWidth: .infinity)

                // Right: Context Panel
                contextPanel
                    .frame(width: 320)
            }

            // Turn Summary Overlay
            if showTurnSummary && !gameManager.turnEvents.isEmpty {
                TurnSummaryOverlay(
                    events: gameManager.turnEvents,
                    turn: gameManager.currentTurn,
                    isPresented: $showTurnSummary
                )
            }

            // Victory Screen
            if let winner = winner {
                VictoryScreenView(
                    winner: winner,
                    turns: gameManager.currentTurn,
                    isPresented: .constant(true)
                )
            }
        }
        .onAppear {
            if !gameManager.gameStarted {
                gameManager.initializeGame()
            }
        }
    }

    // MARK: - Top Bar

    var topBar: some View {
        VStack(spacing: 8) {
            HStack {
                // Turn indicator
                Text("Turn \(gameManager.currentTurn)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(10)

                Spacer()

                // Goal
                let enemyCount = gameManager.map.villages.filter { $0.owner != "player" }.count
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Conquer all villages")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("\(enemyCount) enemies remaining")
                        .font(.caption)
                        .foregroundColor(enemyCount == 0 ? .green : .orange)
                }
            }
            .padding(.horizontal)

            // Resources
            HStack(spacing: 20) {
                let resources = gameManager.getGlobalResources(playerID: "player")
                ForEach(Resource.getAll(), id: \.self) { resource in
                    HStack(spacing: 6) {
                        Text(resource.emoji)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(resources[resource] ?? 0)")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text(resource.name)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
        .shadow(radius: 2)
    }

    // MARK: - Strategic Map

    var strategicMapView: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(NSColor.controlBackgroundColor).opacity(0.3)

                // Draw connections between villages
                ForEach(gameManager.map.villages, id: \.id) { village in
                    ForEach(gameManager.map.villages.filter { $0.id != village.id }, id: \.id) { other in
                        Path { path in
                            let from = villagePosition(village, in: geometry.size)
                            let to = villagePosition(other, in: geometry.size)
                            path.move(to: from)
                            path.addLine(to: to)
                        }
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    }
                }

                // Draw marching armies
                ForEach(gameManager.armies.filter { $0.isMarching }, id: \.id) { army in
                    if let originID = army.origin,
                       let destID = army.destination,
                       let origin = gameManager.map.villages.first(where: { $0.id == originID }),
                       let destination = gameManager.map.villages.first(where: { $0.id == destID }) {
                        let fromPos = villagePosition(origin, in: geometry.size)
                        let toPos = villagePosition(destination, in: geometry.size)
                        let progress = calculateMarchProgress(army: army, from: origin, to: destination)
                        let currentPos = CGPoint(
                            x: fromPos.x + (toPos.x - fromPos.x) * progress,
                            y: fromPos.y + (toPos.y - fromPos.y) * progress
                        )

                        MarchingArmyView(army: army, isSelected: selectedArmy?.id == army.id)
                            .position(currentPos)
                            .onTapGesture {
                                selectedArmy = army
                                selectedVillage = nil
                            }
                    }
                }

                // Draw villages
                ForEach(gameManager.map.villages, id: \.id) { village in
                    VillageNodeView(
                        village: village,
                        isSelected: selectedVillage?.id == village.id,
                        armyCount: gameManager.getArmiesAt(villageID: village.id).filter { $0.owner == village.owner }.first?.unitCount ?? 0
                    )
                    .position(villagePosition(village, in: geometry.size))
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            selectedVillage = village
                            selectedArmy = nil
                        }
                    }
                }
            }
        }
    }

    func villagePosition(_ village: Village, in size: CGSize) -> CGPoint {
        let mapWidth = CGFloat(gameManager.map.size.width)
        let mapHeight = CGFloat(gameManager.map.size.height)
        let padding: CGFloat = 60

        let x = padding + (village.coordinates.x / mapWidth) * (size.width - padding * 2)
        let y = padding + (village.coordinates.y / mapHeight) * (size.height - padding * 2)

        return CGPoint(x: x, y: y)
    }

    func calculateMarchProgress(army: Army, from origin: Village, to destination: Village) -> CGFloat {
        let totalTurns = Army.calculateTravelTime(from: origin.coordinates, to: destination.coordinates)
        let remaining = army.turnsUntilArrival
        return CGFloat(totalTurns - remaining) / CGFloat(totalTurns)
    }

    // MARK: - Bottom Bar

    var bottomBar: some View {
        HStack(spacing: 20) {
            // Army summary
            let playerArmies = gameManager.getArmiesFor(playerID: "player")
            let totalUnits = playerArmies.reduce(0) { $0 + $1.unitCount }
            let marchingCount = playerArmies.filter { $0.isMarching }.count

            HStack(spacing: 16) {
                Label("\(playerArmies.count) armies", systemImage: "flag.fill")
                Label("\(totalUnits) soldiers", systemImage: "person.3.fill")
                if marchingCount > 0 {
                    Label("\(marchingCount) marching", systemImage: "arrow.right.circle")
                        .foregroundColor(.orange)
                }
            }
            .font(.subheadline)

            Spacer()

            // Next Turn Button
            Button(action: {
                processTurn()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: isProcessingTurn ? "hourglass" : "arrow.right.circle.fill")
                        .font(.title2)
                    Text(isProcessingTurn ? "Processing..." : "End Turn")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(isProcessingTurn ? Color.orange : Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(isProcessingTurn)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .shadow(radius: 2)
    }

    func processTurn() {
        withAnimation {
            isProcessingTurn = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            gameManager.turnEngine.doTurn()

            // IMPORTANT: Refresh selected village/army after turn processing
            // The owner may have changed, or the entity may have been destroyed
            refreshSelection()

            withAnimation {
                isProcessingTurn = false
                // Show turn summary if there are events
                if !gameManager.turnEvents.isEmpty {
                    showTurnSummary = true
                }
            }

            // Force UI refresh
            gameManager.objectWillChange.send()
        }
    }

    func refreshSelection() {
        // Refresh selected village from current game state
        if let village = selectedVillage {
            // Find the village by ID in current map state
            if let updatedVillage = gameManager.map.villages.first(where: { $0.id == village.id }) {
                selectedVillage = updatedVillage
            } else {
                // Village was destroyed
                selectedVillage = nil
            }
        }

        // Refresh selected army
        if let army = selectedArmy {
            if let updatedArmy = gameManager.armies.first(where: { $0.id == army.id }) {
                selectedArmy = updatedArmy
            } else {
                // Army was destroyed
                selectedArmy = nil
            }
        }
    }

    // MARK: - Context Panel

    var contextPanel: some View {
        VStack(spacing: 0) {
            // Panel header
            HStack {
                if let village = selectedVillage {
                    Text(village.name)
                        .font(.headline)
                } else if let army = selectedArmy {
                    Text(army.name)
                        .font(.headline)
                } else {
                    Text("Select a village")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Panel content
            ScrollView {
                if let village = selectedVillage {
                    VillagePanel(
                        village: village,
                        onSendArmy: { army, destination in
                            _ = gameManager.sendArmy(armyID: army.id, to: destination.id)
                            // Refresh selection
                            if let coords = selectedVillage?.coordinates {
                                selectedVillage = gameManager.map.getVillageAt(x: Int(coords.x), y: Int(coords.y))
                            }
                        },
                        onUpdate: {
                            // Refresh village data
                            if let id = selectedVillage?.id {
                                selectedVillage = gameManager.map.villages.first { $0.id == id }
                            }
                        }
                    )
                } else if let army = selectedArmy {
                    ArmyPanel(army: army)
                } else {
                    EmpireOverviewPanel()
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Village Node View

struct VillageNodeView: View {
    let village: Village
    let isSelected: Bool
    let armyCount: Int

    var body: some View {
        ZStack {
            // Selection ring
            if isSelected {
                Circle()
                    .stroke(Color.blue, lineWidth: 3)
                    .frame(width: 70, height: 70)
            }

            // Village circle
            Circle()
                .fill(villageColor)
                .frame(width: 60, height: 60)
                .shadow(radius: isSelected ? 8 : 4)

            // Flag
            Text(village.nationality.flag)
                .font(.title)

            // Army indicator
            if armyCount > 0 {
                Text("\(armyCount)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color.red)
                    .clipShape(Circle())
                    .offset(x: 22, y: -22)
            }

            // Village name
            Text(village.name)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(NSColor.windowBackgroundColor).opacity(0.9))
                .cornerRadius(4)
                .offset(y: 45)
        }
    }

    var villageColor: Color {
        if village.owner == "player" {
            return Color.green
        } else {
            return Color.red
        }
    }
}

// MARK: - Marching Army View

struct MarchingArmyView: View {
    let army: Army
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(army.owner == "player" ? Color.blue : Color.red)
                .frame(width: 30, height: 30)
                .shadow(radius: isSelected ? 6 : 3)

            Text(army.emoji)
                .font(.caption)

            // Unit count
            Text("\(army.unitCount)")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .padding(2)
                .background(Color.black.opacity(0.7))
                .clipShape(Circle())
                .offset(x: 12, y: -12)
        }
    }
}

// MARK: - Village Panel

struct VillagePanel: View {
    let village: Village
    let onSendArmy: (Army, Village) -> Void
    let onUpdate: () -> Void

    @State private var showBuild = false
    @State private var showRecruit = false
    @State private var showSendArmy = false

    var isPlayerVillage: Bool {
        village.owner == "player"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Village info
            HStack {
                Text(village.nationality.flag)
                    .font(.largeTitle)
                VStack(alignment: .leading) {
                    Text(village.level.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack {
                        Label("\(village.population)", systemImage: "person.3.fill")
                        Label("\(village.totalHappiness)%", systemImage: "face.smiling")
                    }
                    .font(.caption)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            if isPlayerVillage {
                // Buildings
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: { showBuild.toggle() }) {
                        HStack {
                            Text("Buildings (\(village.buildings.count)/\(village.maxBuildings))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: showBuild ? "chevron.up" : "chevron.down")
                        }
                    }
                    .buttonStyle(.plain)

                    if showBuild {
                        BuildMenuInlineView(village: village, onUpdate: onUpdate)
                    }
                }

                Divider()

                // Army at village
                armySection

                Divider()

                // Recruit
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: { showRecruit.toggle() }) {
                        HStack {
                            Text("Recruit")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: showRecruit ? "chevron.up" : "chevron.down")
                        }
                    }
                    .buttonStyle(.plain)

                    if showRecruit {
                        RecruitMenuInlineView(village: village, onUpdate: onUpdate)
                    }
                }
            } else {
                // Enemy village info
                enemyVillageInfo
            }
        }
        .padding()
    }

    var armySection: some View {
        let armies = GameManager.shared.getArmiesAt(villageID: village.id).filter { $0.owner == "player" }

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Army")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                let totalUnits = armies.reduce(0) { $0 + $1.unitCount }
                Text("\(totalUnits) soldiers")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if armies.isEmpty {
                Text("No army stationed here")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(armies, id: \.id) { army in
                    ArmyCard(army: army, onSend: {
                        showSendArmy = true
                    })
                }
            }
        }
        .sheet(isPresented: $showSendArmy) {
            if let army = armies.first {
                SendArmySheet(
                    army: army,
                    currentVillage: village,
                    onSend: { destination in
                        onSendArmy(army, destination)
                        showSendArmy = false
                    }
                )
            }
        }
    }

    var enemyVillageInfo: some View {
        let defenderArmies = GameManager.shared.getArmiesAt(villageID: village.id).filter { $0.owner == village.owner }
        let totalDefenders = defenderArmies.reduce(0) { $0 + $1.unitCount }
        let armyStrength = defenderArmies.reduce(0) { $0 + $1.strength }

        // Calculate garrison strength (same formula as CombatEngine)
        let popDefense = village.population / 10
        let levelBonus: Double = {
            switch village.level {
            case .village: return 1.0
            case .town: return 1.5
            case .district: return 2.0
            case .castle: return 3.0
            case .city: return 4.0
            }
        }()
        let garrisonStrength = max(Int(Double(popDefense) * levelBonus * (1.0 + village.defenseBonus)), 10)
        let totalStrength = armyStrength + garrisonStrength

        return VStack(alignment: .leading, spacing: 8) {
            Label("Enemy Village", systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .foregroundColor(.red)

            Divider()

            HStack {
                Text("Army:")
                Spacer()
                if totalDefenders > 0 {
                    Text("\(totalDefenders) soldiers (str: \(armyStrength))")
                        .fontWeight(.medium)
                } else {
                    Text("None")
                        .foregroundColor(.secondary)
                }
            }
            .font(.caption)

            HStack {
                Text("Garrison:")
                Spacer()
                Text("\(garrisonStrength) (from \(village.population) pop)")
                    .fontWeight(.medium)
            }
            .font(.caption)

            HStack {
                Text("Defense Bonus:")
                Spacer()
                Text("+\(Int(village.defenseBonus * 100))%")
                    .fontWeight(.medium)
            }
            .font(.caption)

            Divider()

            HStack {
                Text("Total Defense:")
                Spacer()
                Text("\(totalStrength)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }

            Text("You need ~\(Int(Double(totalStrength) * 1.5)) attack strength to win")
                .font(.caption2)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Army Card

struct ArmyCard: View {
    let army: Army
    let onSend: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(army.emoji)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(army.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("\(army.unitCount) soldiers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Send") {
                    onSend()
                }
                .buttonStyle(.borderedProminent)
            }

            // Combat stats
            HStack(spacing: 12) {
                Label("\(army.totalAttack)", systemImage: "burst.fill")
                    .foregroundColor(.orange)
                Label("\(army.totalDefense)", systemImage: "shield.fill")
                    .foregroundColor(.blue)
                Spacer()
                Text("Strength: \(army.strength)")
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            .font(.caption)
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Army Panel (for selected marching armies)

struct ArmyPanel: View {
    let army: Army

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Army info
            HStack {
                Text(army.emoji)
                    .font(.largeTitle)
                VStack(alignment: .leading) {
                    Text(army.name)
                        .font(.headline)
                    Text("\(army.unitCount) soldiers")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if army.isMarching {
                // Marching status
                VStack(alignment: .leading, spacing: 8) {
                    Label("Marching", systemImage: "arrow.right.circle")
                        .font(.subheadline)
                        .foregroundColor(.orange)

                    if let destID = army.destination,
                       let dest = GameManager.shared.map.villages.first(where: { $0.id == destID }) {
                        HStack {
                            Text("Destination:")
                            Spacer()
                            Text(dest.name)
                                .fontWeight(.medium)
                        }

                        HStack {
                            Text("Arrives in:")
                            Spacer()
                            Text("\(army.turnsUntilArrival) turns")
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .font(.caption)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            // Unit breakdown
            VStack(alignment: .leading, spacing: 8) {
                Text("Unit Composition")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                let grouped = Dictionary(grouping: army.units, by: { $0.unitType })
                ForEach(Array(grouped.keys), id: \.self) { type in
                    HStack {
                        Text(type.emoji)
                        Text(type.rawValue.capitalized)
                        Spacer()
                        Text("×\(grouped[type]?.count ?? 0)")
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                }
            }

            // Stats
            VStack(alignment: .leading, spacing: 4) {
                Text("Combat Stats")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack {
                    Label("\(army.totalAttack)", systemImage: "burst.fill")
                        .foregroundColor(.red)
                    Label("\(army.totalDefense)", systemImage: "shield.fill")
                        .foregroundColor(.blue)
                    Label("\(army.totalHP)", systemImage: "heart.fill")
                        .foregroundColor(.green)
                }
                .font(.caption)
            }
        }
        .padding()
    }
}

// MARK: - Empire Overview Panel

struct EmpireOverviewPanel: View {
    @ObservedObject var gameManager = GameManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Empire")
                .font(.headline)

            // Villages
            let villages = gameManager.getPlayerVillages(playerID: "player")
            VStack(alignment: .leading, spacing: 8) {
                Text("Villages (\(villages.count))")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                ForEach(villages, id: \.id) { village in
                    HStack {
                        Text(village.nationality.flag)
                        Text(village.name)
                            .font(.caption)
                        Spacer()
                        Text("\(village.population) pop")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()

            // Armies
            let armies = gameManager.getArmiesFor(playerID: "player")
            VStack(alignment: .leading, spacing: 8) {
                Text("Armies (\(armies.count))")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if armies.isEmpty {
                    Text("No armies yet.\nBuild a Barracks and recruit soldiers!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(armies, id: \.id) { army in
                        HStack {
                            Text(army.emoji)
                            Text(army.name)
                                .font(.caption)
                            Spacer()
                            if army.isMarching {
                                Text("⏳ \(army.turnsUntilArrival)t")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            } else {
                                Text("\(army.unitCount) units")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Send Army Sheet

struct SendArmySheet: View {
    let army: Army
    let currentVillage: Village
    let onSend: (Village) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Send \(army.name)")
                .font(.title2)
                .fontWeight(.bold)

            Text("Select destination:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            let targets = GameManager.shared.map.villages.filter { $0.id != currentVillage.id }

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(targets, id: \.id) { target in
                        Button(action: {
                            onSend(target)
                        }) {
                            HStack {
                                Text(target.nationality.flag)
                                    .font(.title2)

                                VStack(alignment: .leading) {
                                    Text(target.name)
                                        .font(.headline)
                                    let turns = Army.calculateTravelTime(
                                        from: currentVillage.coordinates,
                                        to: target.coordinates
                                    )
                                    Text("\(turns) turns away")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if target.owner != "player" {
                                    Label("Enemy", systemImage: "exclamationmark.triangle.fill")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                } else {
                                    Label("Friendly", systemImage: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }

            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .frame(width: 400, height: 500)
        .padding()
    }
}

// MARK: - Turn Summary Overlay

struct TurnSummaryOverlay: View {
    let events: [TurnEvent]
    let turn: Int
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Turn \(turn) Complete")
                    .font(.title)
                    .fontWeight(.bold)

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // Important events first
                        let important = events.filter { $0.isImportant }
                        if !important.isEmpty {
                            Text("Important")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)

                            ForEach(important) { event in
                                EventRow(event: event)
                            }
                        }

                        // Other events
                        let other = events.filter { !$0.isImportant }
                        if !other.isEmpty {
                            Text("Events")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)

                            ForEach(other) { event in
                                EventRow(event: event)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                .frame(maxHeight: 300)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)

                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .padding(30)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(20)
            .shadow(radius: 20)
            .frame(maxWidth: 500)
        }
    }
}

struct EventRow: View {
    let event: TurnEvent

    var body: some View {
        HStack {
            Text(event.emoji)
                .font(.title3)
            Text(event.message)
                .font(.subheadline)
            Spacer()
        }
        .padding(8)
        .background(event.isImportant ? Color.red.opacity(0.1) : Color.clear)
        .cornerRadius(6)
    }
}

