//
//  GameView.swift
//  VillagesTown
//
//  Strategic game view with polished UX
//

import SwiftUI

// MARK: - Keyboard Shortcuts (macOS only)

#if os(macOS)
struct KeyboardShortcutsModifier: ViewModifier {
    let onEndTurn: () -> Void
    let onEscape: () -> Void
    let onSelectVillage: (Int) -> Void

    func body(content: Content) -> some View {
        if #available(macOS 14.0, *) {
            content
                .onKeyPress(.space) { onEndTurn(); return .handled }
                .onKeyPress(.return) { onEndTurn(); return .handled }
                .onKeyPress(.escape) { onEscape(); return .handled }
                .onKeyPress(characters: CharacterSet(charactersIn: "1234")) { press in
                    if let char = press.characters.first, let index = Int(String(char)) {
                        onSelectVillage(index)
                    }
                    return .handled
                }
        } else {
            content
        }
    }
}
#endif

// MARK: - Color Theme
extension Color {
    static let playerGreen = Color(red: 0.2, green: 0.7, blue: 0.4)
    static let playerGreenDark = Color(red: 0.1, green: 0.5, blue: 0.3)
    static let enemyRed = Color(red: 0.8, green: 0.2, blue: 0.2)
    static let enemyRedDark = Color(red: 0.6, green: 0.1, blue: 0.1)
    static let neutralGray = Color(red: 0.5, green: 0.5, blue: 0.55)
    static let ai1Color = Color(red: 0.8, green: 0.3, blue: 0.3)
    static let ai2Color = Color(red: 0.6, green: 0.3, blue: 0.7)
    static let mapBackground = Color(red: 0.15, green: 0.18, blue: 0.22)
    static let panelBackground = Color(red: 0.12, green: 0.14, blue: 0.18)
    static let cardBackground = Color(red: 0.18, green: 0.2, blue: 0.25)
}

struct GameView: View {
    @ObservedObject var gameManager = GameManager.shared
    @State private var selectedVillage: Village?
    @State private var selectedArmy: Army?
    @State private var showTurnSummary = false
    @State private var isProcessingTurn = false
    @State private var isSpectating = false
    @State private var showGameEndScreen = true
    @State private var toastEvents: [TurnEvent] = []
    @State private var mapScale: CGFloat = 1.0
    @State private var hoveredVillage: Village?

    var winner: Player? {
        let activePlayers = gameManager.players.filter { !$0.isEliminated }
        return activePlayers.count == 1 ? activePlayers.first : nil
    }

    var playerEliminated: Bool {
        gameManager.players.first(where: { $0.isHuman })?.isEliminated ?? false
    }

    var body: some View {
        ZStack {
            // Dark background
            Color.mapBackground.ignoresSafeArea()

            // Main game content
            HStack(spacing: 0) {
                // Left: Strategic Map
                VStack(spacing: 0) {
                    topBar
                    strategicMapView
                    bottomBar
                }
                .frame(maxWidth: .infinity)

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1)

                // Right: Context Panel
                contextPanel
                    .frame(width: 340)
            }

            // Toast notifications (non-blocking)
            VStack {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        ForEach(toastEvents) { event in
                            ToastView(event: event)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                    }
                    .padding()
                }
                Spacer()
            }
            .padding(.top, 80)

            // Game End Screens
            if showGameEndScreen {
                if let winner = winner {
                    VictoryScreenView(
                        winner: winner,
                        turns: gameManager.currentTurn,
                        isPresented: $showGameEndScreen,
                        onContinueWatching: {
                            isSpectating = true
                            showGameEndScreen = false
                        }
                    )
                } else if playerEliminated && !isSpectating {
                    DefeatScreenView(
                        turn: gameManager.currentTurn,
                        onContinueWatching: {
                            isSpectating = true
                            showGameEndScreen = false
                        },
                        onQuit: {
                            gameManager.playerNationality = nil
                        }
                    )
                }
            }

            // Spectator mode indicator
            if isSpectating {
                VStack {
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "eye.fill")
                            Text("SPECTATOR")
                                .fontWeight(.bold)
                        }
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [.purple, .purple.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .shadow(color: .purple.opacity(0.5), radius: 8)
                        Spacer()
                    }
                    .padding()
                    Spacer()
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if !gameManager.gameStarted {
                gameManager.initializeGame()
            }
            // Auto-select first player village
            if selectedVillage == nil {
                selectedVillage = gameManager.getPlayerVillages(playerID: "player").first
            }
        }
        #if os(macOS)
        .modifier(KeyboardShortcutsModifier(
            onEndTurn: { if !isProcessingTurn { processTurn() } },
            onEscape: { selectedVillage = nil; selectedArmy = nil },
            onSelectVillage: { index in
                let villages = gameManager.getPlayerVillages(playerID: "player")
                if index >= 1 && index <= villages.count {
                    selectedVillage = villages[index - 1]
                    selectedArmy = nil
                }
            }
        ))
        #endif
    }

    // MARK: - Top Bar

    var topBar: some View {
        HStack(spacing: 0) {
            // Turn indicator with pulsing effect
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 40, height: 40)
                    Text("\(gameManager.currentTurn)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("TURN")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.6))
                    Text(getCurrentSeason())
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 16)

            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.2))

            // Resources with production indicators
            HStack(spacing: 24) {
                ForEach(Resource.getAll(), id: \.self) { resource in
                    ResourceDisplay(
                        resource: resource,
                        amount: gameManager.getGlobalResources(playerID: "player")[resource] ?? 0,
                        production: getProduction(for: resource)
                    )
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            // Victory progress
            VictoryProgressView(
                playerVillages: gameManager.getPlayerVillages(playerID: "player").count,
                totalVillages: gameManager.map.villages.count
            )
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(Color.panelBackground)
    }

    func getCurrentSeason() -> String {
        let seasons = ["Spring", "Summer", "Autumn", "Winter"]
        let turn = max(gameManager.currentTurn, 1)
        return seasons[(turn - 1) % 4]
    }

    func getProduction(for resource: Resource) -> Int {
        // Calculate approximate production per turn
        let villages = gameManager.getPlayerVillages(playerID: "player")
        var production = 0
        for village in villages {
            for building in village.buildings {
                if let prod = building.resourcesProduction[resource] {
                    production += prod
                }
            }
        }
        return production
    }

    // MARK: - Strategic Map

    // FOG OF WAR: Get visible villages and armies
    var visibleVillages: [Village] {
        gameManager.getVisibleVillages(for: "player")
    }

    var visibleArmies: [Army] {
        gameManager.getVisibleArmies(for: "player")
    }

    var strategicMapView: some View {
        GeometryReader { geometry in
            ZStack {
                // Terrain-like background
                MapBackgroundView()

                // Draw army movement paths (dashed lines) - ONLY FOR VISIBLE ARMIES
                ForEach(visibleArmies.filter { $0.isMarching }, id: \.id) { army in
                    if let originID = army.origin,
                       let destID = army.destination,
                       let origin = gameManager.map.villages.first(where: { $0.id == originID }),
                       let destination = gameManager.map.villages.first(where: { $0.id == destID }) {
                        ArmyPathView(
                            from: villagePosition(origin, in: geometry.size),
                            to: villagePosition(destination, in: geometry.size),
                            progress: calculateMarchProgress(army: army, from: origin, to: destination),
                            isPlayer: army.owner == "player"
                        )
                    }
                }

                // Draw subtle connections between VISIBLE villages only
                ForEach(visibleVillages, id: \.id) { village in
                    ForEach(getConnectedVillages(for: village).filter { other in
                        visibleVillages.contains { $0.id == other.id }
                    }, id: \.id) { other in
                        Path { path in
                            let from = villagePosition(village, in: geometry.size)
                            let to = villagePosition(other, in: geometry.size)
                            path.move(to: from)
                            path.addLine(to: to)
                        }
                        .stroke(
                            Color.white.opacity(0.08),
                            style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                        )
                    }
                }

                // Draw HIDDEN villages (fog markers)
                ForEach(gameManager.map.villages.filter { village in
                    !visibleVillages.contains { $0.id == village.id }
                }, id: \.id) { village in
                    FoggedVillageView()
                        .position(villagePosition(village, in: geometry.size))
                }

                // Draw marching armies - ONLY VISIBLE
                ForEach(visibleArmies.filter { $0.isMarching }, id: \.id) { army in
                    if let originID = army.origin,
                       let destID = army.destination,
                       let origin = gameManager.map.villages.first(where: { $0.id == originID }),
                       let destination = gameManager.map.villages.first(where: { $0.id == destID }) {
                        let progress = calculateMarchProgress(army: army, from: origin, to: destination)
                        let fromPos = villagePosition(origin, in: geometry.size)
                        let toPos = villagePosition(destination, in: geometry.size)
                        let currentPos = CGPoint(
                            x: fromPos.x + (toPos.x - fromPos.x) * progress,
                            y: fromPos.y + (toPos.y - fromPos.y) * progress
                        )

                        MarchingArmyView(
                            army: army,
                            isSelected: selectedArmy?.id == army.id,
                            turnsRemaining: army.turnsUntilArrival
                        )
                        .position(currentPos)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedArmy = army
                                selectedVillage = nil
                            }
                        }
                    }
                }

                // Draw VISIBLE villages
                ForEach(visibleVillages, id: \.id) { village in
                    let armies = gameManager.getArmiesAt(villageID: village.id).filter { $0.owner == village.owner }
                    let armyStrength = armies.reduce(0) { $0 + $1.strength }
                    let allUnits = armies.flatMap { $0.units }

                    VillageNodeView(
                        village: village,
                        isSelected: selectedVillage?.id == village.id,
                        isHovered: hoveredVillage?.id == village.id,
                        armyCount: armies.first?.unitCount ?? 0,
                        armyStrength: armyStrength,
                        unitComposition: allUnits,
                        hasIncomingThreat: hasIncomingThreat(to: village)
                    )
                    .position(villagePosition(village, in: geometry.size))
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedVillage = village
                            selectedArmy = nil
                        }
                    }
                    #if os(macOS)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            hoveredVillage = hovering ? village : nil
                        }
                    }
                    #endif
                }
            }
            .scaleEffect(mapScale)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        mapScale = min(max(value, 0.8), 1.5)
                    }
            )
        }
    }

    func getConnectedVillages(for village: Village) -> [Village] {
        // Return only nearby villages (adjacent connections)
        gameManager.map.villages.filter { other in
            guard other.id != village.id else { return false }
            let dist = distance(from: village.coordinates, to: other.coordinates)
            // Only connect to immediate neighbors (reduced from 8 to 6)
            return dist < 6 && dist > 0
        }
    }

    func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        sqrt(pow(to.x - from.x, 2) + pow(to.y - from.y, 2))
    }

    func hasIncomingThreat(to village: Village) -> Bool {
        gameManager.armies.contains { army in
            army.isMarching &&
            army.destination == village.id &&
            army.owner != village.owner
        }
    }

    func villagePosition(_ village: Village, in size: CGSize) -> CGPoint {
        let mapWidth = CGFloat(gameManager.map.size.width)
        let mapHeight = CGFloat(gameManager.map.size.height)
        let padding: CGFloat = 80

        let x = padding + (village.coordinates.x / mapWidth) * (size.width - padding * 2)
        let y = padding + (village.coordinates.y / mapHeight) * (size.height - padding * 2)

        return CGPoint(x: x, y: y)
    }

    func calculateMarchProgress(army: Army, from origin: Village, to destination: Village) -> CGFloat {
        let totalTurns = Army.calculateTravelTime(from: origin.coordinates, to: destination.coordinates)
        let remaining = army.turnsUntilArrival
        return CGFloat(totalTurns - remaining) / CGFloat(max(totalTurns, 1))
    }

    // MARK: - Bottom Bar

    var bottomBar: some View {
        HStack(spacing: 20) {
            // Army overview pills
            let playerArmies = gameManager.getArmiesFor(playerID: "player")
            let totalUnits = playerArmies.reduce(0) { $0 + $1.unitCount }
            let marchingCount = playerArmies.filter { $0.isMarching }.count
            let totalStrength = playerArmies.reduce(0) { $0 + $1.strength }

            HStack(spacing: 12) {
                StatPill(icon: "flag.fill", value: "\(playerArmies.count)", label: "Armies", color: .blue)
                StatPill(icon: "person.3.fill", value: "\(totalUnits)", label: "Soldiers", color: .green)
                StatPill(icon: "bolt.fill", value: "\(totalStrength)", label: "Strength", color: .orange)
                if marchingCount > 0 {
                    StatPill(icon: "arrow.right.circle.fill", value: "\(marchingCount)", label: "Marching", color: .purple)
                }
            }

            Spacer()

            // End Turn Button
            Button(action: { processTurn() }) {
                VStack(spacing: 2) {
                    HStack(spacing: 10) {
                        if isProcessingTurn {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "forward.fill")
                                .font(.title3)
                        }
                        Text(isProcessingTurn ? "Processing..." : "End Turn")
                            .fontWeight(.semibold)
                    }
                    if !isProcessingTurn {
                        Text("⎵ Space")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: isProcessingTurn
                            ? [.orange, .orange.opacity(0.8)]
                            : [.playerGreen, .playerGreenDark],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: (isProcessingTurn ? Color.orange : Color.playerGreen).opacity(0.4), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(isProcessingTurn)
            .scaleEffect(isProcessingTurn ? 0.98 : 1.0)
            .animation(.spring(response: 0.3), value: isProcessingTurn)
            .help("End your turn (Space or Enter)")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.panelBackground)
    }

    func processTurn() {
        withAnimation(.spring(response: 0.3)) {
            isProcessingTurn = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            gameManager.turnEngine.doTurn()
            refreshSelection()

            // Show events as toasts instead of blocking modal
            let events = gameManager.turnEvents
            showToasts(for: events)

            withAnimation(.spring(response: 0.3)) {
                isProcessingTurn = false
            }

            gameManager.objectWillChange.send()
        }
    }

    func showToasts(for events: [TurnEvent]) {
        // Show important events as toasts
        let importantEvents = events.filter { $0.isImportant }
        for (index, event) in importantEvents.prefix(3).enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.3) {
                withAnimation(.spring(response: 0.4)) {
                    toastEvents.append(event)
                }
            }
            // Auto-dismiss after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.3 + 4.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    toastEvents.removeAll { $0.id == event.id }
                }
            }
        }
    }

    func refreshSelection() {
        if let village = selectedVillage {
            if let updatedVillage = gameManager.map.villages.first(where: { $0.id == village.id }) {
                selectedVillage = updatedVillage
            } else {
                selectedVillage = nil
            }
        }

        if let army = selectedArmy {
            if let updatedArmy = gameManager.armies.first(where: { $0.id == army.id }) {
                selectedArmy = updatedArmy
            } else {
                selectedArmy = nil
            }
        }
    }

    // MARK: - Context Panel

    var contextPanel: some View {
        let playerVillages = gameManager.getPlayerVillages(playerID: "player")

        return VStack(spacing: 0) {
            // Village quick-select tabs
            if playerVillages.count > 1 {
                HStack(spacing: 4) {
                    ForEach(Array(playerVillages.enumerated()), id: \.element.id) { index, village in
                        Button(action: {
                            withAnimation(.spring(response: 0.2)) {
                                selectedVillage = village
                                selectedArmy = nil
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text("\(index + 1)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary)
                                Text(village.nationality.flag)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(selectedVillage?.id == village.id ? Color.blue.opacity(0.3) : Color.cardBackground)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 4)
            }

            // Panel header with gradient
            HStack {
                if let village = selectedVillage {
                    HStack(spacing: 10) {
                        Text(village.nationality.flag)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(village.name)
                                .font(.headline)
                                .fontWeight(.bold)
                            Text(village.level.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else if let army = selectedArmy {
                    HStack(spacing: 10) {
                        Text(army.emoji)
                            .font(.title2)
                        Text(army.name)
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "map.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("Empire Overview")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color.cardBackground, Color.panelBackground],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Panel content
            ScrollView {
                if let village = selectedVillage {
                    VillagePanel(
                        village: village,
                        onSendArmy: { army, destination in
                            _ = gameManager.sendArmy(armyID: army.id, to: destination.id)
                            if let coords = selectedVillage?.coordinates {
                                selectedVillage = gameManager.map.getVillageAt(x: Int(coords.x), y: Int(coords.y))
                            }
                        },
                        onUpdate: {
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
        .background(Color.panelBackground)
    }
}

// MARK: - Supporting Views

// MARK: - Fogged Village (hidden by fog of war)

struct FoggedVillageView: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            // Fog circle
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 50, height: 50)
                .blur(radius: 8)

            // Mystery marker
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)

            Text("?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.4))
        }
        .opacity(pulse ? 0.6 : 0.8)
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = true }
    }
}

struct MapBackgroundView: View {
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.15, blue: 0.2),
                    Color(red: 0.08, green: 0.1, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle grid pattern
            Canvas { context, size in
                let gridSize: CGFloat = 40
                for x in stride(from: 0, to: size.width, by: gridSize) {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(path, with: .color(.white.opacity(0.03)), lineWidth: 1)
                }
                for y in stride(from: 0, to: size.height, by: gridSize) {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: .color(.white.opacity(0.03)), lineWidth: 1)
                }
            }
        }
    }
}

struct ResourceDisplay: View {
    let resource: Resource
    let amount: Int
    let production: Int

    var isLow: Bool { amount < 20 }
    var isCritical: Bool { amount < 5 }

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Text(resource.emoji)
                    .font(.title3)
                // Critical warning badge
                if isCritical {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.red)
                        .offset(x: 10, y: -8)
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Text("\(amount)")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(isCritical ? .red : (isLow ? .orange : .white))

                    if production > 0 {
                        Text("+\(production)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    } else if production < 0 {
                        Text("\(production)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                }
                Text(resource.name)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isCritical ? Color.red.opacity(0.15) : Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isCritical ? Color.red.opacity(0.6) : (isLow ? Color.orange.opacity(0.4) : Color.clear), lineWidth: 1)
                )
        )
        .help("\(resource.name): \(amount) (income: \(production >= 0 ? "+" : "")\(production)/turn)")
    }
}

struct VictoryProgressView: View {
    let playerVillages: Int
    let totalVillages: Int

    var progress: CGFloat {
        CGFloat(playerVillages) / CGFloat(max(totalVillages, 1))
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("DOMINATION")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))

            HStack(spacing: 8) {
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.playerGreen, .green],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(width: 80, height: 8)

                Text("\(playerVillages)/\(totalVillages)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .cornerRadius(16)
    }
}

struct ArmyPathView: View {
    let from: CGPoint
    let to: CGPoint
    let progress: CGFloat
    let isPlayer: Bool

    var body: some View {
        ZStack {
            // Full path (dimmed)
            Path { path in
                path.move(to: from)
                path.addLine(to: to)
            }
            .stroke(
                (isPlayer ? Color.blue : Color.red).opacity(0.2),
                style: StrokeStyle(lineWidth: 3, dash: [8, 4])
            )

            // Progress path (bright)
            Path { path in
                path.move(to: from)
                let currentX = from.x + (to.x - from.x) * progress
                let currentY = from.y + (to.y - from.y) * progress
                path.addLine(to: CGPoint(x: currentX, y: currentY))
            }
            .stroke(
                isPlayer ? Color.blue : Color.red,
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
        }
    }
}

struct ToastView: View {
    let event: TurnEvent

    var body: some View {
        HStack(spacing: 10) {
            Text(event.emoji)
                .font(.title3)

            Text(event.message)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(event.isImportant ? Color.red.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Village Node View

struct VillageNodeView: View {
    let village: Village
    let isSelected: Bool
    let isHovered: Bool
    let armyCount: Int
    let armyStrength: Int
    let unitComposition: [Unit]
    let hasIncomingThreat: Bool

    @State private var pulseAnimation = false

    // Group units by type for display
    var unitGroups: [(type: Unit.UnitType, count: Int)] {
        let grouped = Dictionary(grouping: unitComposition, by: { $0.unitType })
        return grouped.map { (type: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }  // Sort by count descending
    }

    var ownerColor: Color {
        switch village.owner {
        case "player": return .playerGreen
        case "ai1": return .ai1Color
        case "ai2": return .ai2Color
        case "neutral": return .neutralGray
        default: return .gray
        }
    }

    // Get owner's flag (from stored nationalities, not village)
    var ownerFlag: String {
        let game = GameManager.shared
        switch village.owner {
        case "player":
            return game.playerNationality?.flag ?? "🏳️"
        case "ai1":
            return game.ai1Nationality?.flag ?? "🔴"
        case "ai2":
            return game.ai2Nationality?.flag ?? "🟣"
        case "neutral":
            return "⚪"
        default:
            return "🏳️"
        }
    }

    var ownerName: String {
        switch village.owner {
        case "player": return "YOU"
        case "ai1": return "AI-1"
        case "ai2": return "AI-2"
        case "neutral": return "Neutral"
        default: return "???"
        }
    }

    var levelIcon: String {
        switch village.level {
        case .village: return "house.fill"
        case .town: return "building.2.fill"
        case .district: return "building.columns.fill"
        case .castle: return "building.fill"
        case .city: return "building.2.crop.circle.fill"
        }
    }

    var body: some View {
        ZStack {
            // Threat pulse
            if hasIncomingThreat {
                Circle()
                    .stroke(Color.red.opacity(0.5), lineWidth: 3)
                    .frame(width: 90, height: 90)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .opacity(pulseAnimation ? 0 : 0.8)
                    .animation(
                        .easeOut(duration: 1.0).repeatForever(autoreverses: false),
                        value: pulseAnimation
                    )
                    .onAppear { pulseAnimation = true }
            }

            // Selection/hover ring
            Circle()
                .stroke(
                    isSelected ? Color.white : (isHovered ? ownerColor.opacity(0.6) : Color.clear),
                    lineWidth: isSelected ? 3 : 2
                )
                .frame(width: 76, height: 76)

            // Glow effect
            Circle()
                .fill(ownerColor.opacity(0.3))
                .frame(width: 70, height: 70)
                .blur(radius: 10)

            // Main circle with gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [ownerColor, ownerColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)
                .shadow(color: ownerColor.opacity(0.5), radius: isSelected ? 12 : 6)

            // Owner's flag (not village nationality)
            Text(ownerFlag)
                .font(.system(size: 32))

            // Level indicator (small icon at bottom of circle)
            Image(systemName: levelIcon)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.8))
                .offset(y: 20)

            // Garrison shield (bottom left)
            HStack(spacing: 2) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 8))
                Text("\(village.garrisonStrength)")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.6))
            .cornerRadius(8)
            .offset(x: -24, y: 24)

            // Army indicator (top right) - shows unit composition
            if armyCount > 0 {
                HStack(spacing: 3) {
                    // Show up to 3 unit type emojis
                    ForEach(unitGroups.prefix(3), id: \.type) { group in
                        HStack(spacing: 1) {
                            Text(group.type.emoji)
                                .font(.system(size: 9))
                            if group.count > 1 {
                                Text("\(group.count)")
                                    .font(.system(size: 7, weight: .bold))
                            }
                        }
                    }
                    // If more than 3 types, show +
                    if unitGroups.count > 3 {
                        Text("+")
                            .font(.system(size: 8, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.blue)
                )
                .offset(x: 30, y: -26)
            }

            // Village name + owner label
            VStack(spacing: 2) {
                Text(village.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)

                Text(ownerName)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(ownerColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.8))
            )
            .offset(y: 52)
        }
        .scaleEffect(isSelected ? 1.1 : (isHovered ? 1.05 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isHovered)
    }
}

// MARK: - Marching Army View

struct MarchingArmyView: View {
    let army: Army
    let isSelected: Bool
    let turnsRemaining: Int

    var ownerColor: Color {
        switch army.owner {
        case "player": return .blue
        case "ai1": return .ai1Color
        case "ai2": return .ai2Color
        default: return .gray
        }
    }

    // Group units by type for display
    var unitGroups: [(type: Unit.UnitType, count: Int)] {
        let grouped = Dictionary(grouping: army.units, by: { $0.unitType })
        return grouped.map { (type: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        ZStack {
            // Selection ring
            if isSelected {
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 50, height: 50)
            }

            // Glow
            Circle()
                .fill(ownerColor.opacity(0.3))
                .frame(width: 40, height: 40)
                .blur(radius: 6)

            // Main circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [ownerColor, ownerColor.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 36, height: 36)
                .shadow(color: ownerColor.opacity(0.5), radius: 6)

            // Unit composition icons (top of circle)
            HStack(spacing: 2) {
                ForEach(unitGroups.prefix(3), id: \.type) { group in
                    Text(group.type.emoji)
                        .font(.system(size: 8))
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.7))
            .cornerRadius(6)
            .offset(y: -24)

            // Turns remaining
            Text("\(turnsRemaining)t")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.orange)
                .cornerRadius(6)
                .offset(y: 24)
        }
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Village Panel (Streamlined One-Click UI)

struct VillagePanel: View {
    let village: Village
    let onSendArmy: (Army, Village) -> Void
    let onUpdate: () -> Void

    @State private var showSendArmy = false
    @State private var showMessage = ""
    @State private var showingMessage = false

    let buildingEngine = BuildingConstructionEngine()
    let recruitmentEngine = RecruitmentEngine()

    var isPlayerVillage: Bool {
        village.owner == "player"
    }

    var armies: [Army] {
        GameManager.shared.getArmiesAt(villageID: village.id).filter { $0.owner == "player" }
    }

    var body: some View {
        VStack(spacing: 0) {
            if isPlayerVillage {
                ScrollView {
                    VStack(spacing: 16) {
                        // Quick Stats Bar
                        quickStatsBar

                        // QUICK ACTIONS - Most Important!
                        quickActionsSection

                        Divider().background(Color.white.opacity(0.1))

                        // Army Section
                        armySection

                        Divider().background(Color.white.opacity(0.1))

                        // Buildings Section
                        buildingsSection
                    }
                    .padding()
                }
            } else {
                enemyVillageInfo
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
        .overlay(
            // Toast message
            VStack {
                if showingMessage {
                    Text(showMessage)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
            .padding(.top, 8)
        )
    }

    // MARK: - Quick Stats Bar
    var quickStatsBar: some View {
        HStack(spacing: 16) {
            // Population with growth indicator
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "person.3.fill")
                        .font(.caption2)
                    Text("\(village.population)")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                Text("+~5/turn")
                    .font(.caption2)
                    .foregroundColor(.green)
            }

            Divider().frame(height: 30)

            // Garrison
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "shield.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("\(village.garrisonStrength)")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                Text("/\(village.garrisonMaxStrength)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Divider().frame(height: 30)

            // Buildings
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "building.2.fill")
                        .font(.caption2)
                        .foregroundColor(.purple)
                    Text("\(village.buildings.count)")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                Text("/\(village.maxBuildings)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Divider().frame(height: 30)

            // Army
            let armyCount = armies.reduce(0) { $0 + $1.unitCount }
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "figure.stand")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text("\(armyCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                Text("soldiers")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - Quick Actions (ONE CLICK!)
    var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK ACTIONS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)

            // ONE-CLICK BUILD BUTTONS - Row 1: Economy
            HStack(spacing: 8) {
                QuickBuildButton(
                    icon: "🌾",
                    name: "Farm",
                    building: Building.farm,
                    village: village,
                    onBuild: { quickBuild(Building.farm) }
                )
                QuickBuildButton(
                    icon: "⛏️",
                    name: "Mine",
                    building: Building.ironMine,
                    village: village,
                    onBuild: { quickBuild(Building.ironMine) }
                )
                QuickBuildButton(
                    icon: "🪵",
                    name: "Lumber",
                    building: Building.lumberMill,
                    village: village,
                    onBuild: { quickBuild(Building.lumberMill) }
                )
                QuickBuildButton(
                    icon: "🏪",
                    name: "Market",
                    building: Building.market,
                    village: village,
                    onBuild: { quickBuild(Building.market) }
                )
            }

            // Row 2: Military
            HStack(spacing: 8) {
                QuickBuildButton(
                    icon: "⚔️",
                    name: "Barracks",
                    building: Building.barracks,
                    village: village,
                    onBuild: { quickBuild(Building.barracks) }
                )
                QuickBuildButton(
                    icon: "🏹",
                    name: "Archery",
                    building: Building.archeryRange,
                    village: village,
                    onBuild: { quickBuild(Building.archeryRange) }
                )
                QuickBuildButton(
                    icon: "🐴",
                    name: "Stables",
                    building: Building.stables,
                    village: village,
                    onBuild: { quickBuild(Building.stables) }
                )
                QuickBuildButton(
                    icon: "🏰",
                    name: "Fortress",
                    building: Building.fortress,
                    village: village,
                    onBuild: { quickBuild(Building.fortress) }
                )
            }

            // COMPACT RECRUIT ROW with mobilization limit
            let hasBarracks = village.buildings.contains { $0.name == "Barracks" }
            let hasArcheryRange = village.buildings.contains { $0.name == "Archery Range" }
            let hasStables = village.buildings.contains { $0.name == "Stables" }
            let remainingRecruits = village.maxRecruitsPerTurn - village.recruitsThisTurn

            if hasBarracks || hasArcheryRange || hasStables {
                VStack(alignment: .leading, spacing: 6) {
                    // Show remaining recruits
                    HStack {
                        Text("Recruit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        HStack(spacing: 2) {
                            Text("\(remainingRecruits)/\(village.maxRecruitsPerTurn)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(remainingRecruits > 0 ? .green : .red)
                            Text("left")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    if remainingRecruits > 0 {
                        // Infantry (Barracks)
                        if hasBarracks {
                            HStack(spacing: 6) {
                                CompactRecruitButton(emoji: "🗡️", count: min(2, remainingRecruits), unitType: .militia, village: village) {
                                    quickRecruit(.militia, quantity: min(2, remainingRecruits))
                                }
                                CompactRecruitButton(emoji: "⚔️", count: min(1, remainingRecruits), unitType: .swordsman, village: village) {
                                    quickRecruit(.swordsman, quantity: min(1, remainingRecruits))
                                }
                                CompactRecruitButton(emoji: "🛡️", count: min(1, remainingRecruits), unitType: .spearman, village: village) {
                                    quickRecruit(.spearman, quantity: min(1, remainingRecruits))
                                }
                                Spacer()
                            }
                        }
                        // Ranged (Archery Range)
                        if hasArcheryRange {
                            HStack(spacing: 6) {
                                CompactRecruitButton(emoji: "🏹", count: min(1, remainingRecruits), unitType: .archer, village: village) {
                                    quickRecruit(.archer, quantity: min(1, remainingRecruits))
                                }
                                CompactRecruitButton(emoji: "🎯", count: min(1, remainingRecruits), unitType: .crossbowman, village: village) {
                                    quickRecruit(.crossbowman, quantity: min(1, remainingRecruits))
                                }
                                Spacer()
                            }
                        }
                        // Cavalry (Stables)
                        if hasStables {
                            HStack(spacing: 6) {
                                CompactRecruitButton(emoji: "🐴", count: min(1, remainingRecruits), unitType: .lightCavalry, village: village) {
                                    quickRecruit(.lightCavalry, quantity: min(1, remainingRecruits))
                                }
                                CompactRecruitButton(emoji: "🐎", count: min(1, remainingRecruits), unitType: .knight, village: village) {
                                    quickRecruit(.knight, quantity: min(1, remainingRecruits))
                                }
                                Spacer()
                            }
                        }
                    } else {
                        Text("Mobilization limit reached - wait for next turn")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("Build Barracks/Archery/Stables to recruit")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            // SEND ARMY BUTTON (if has army)
            if !armies.isEmpty {
                Button(action: { showSendArmy = true }) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SEND ARMY")
                                .font(.caption)
                                .fontWeight(.bold)
                            Text("\(armies.first?.unitCount ?? 0) soldiers ready")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
    }

    func quickBuild(_ building: Building) {
        var mutableVillage = village
        if buildingEngine.buildBuilding(building: building, in: &mutableVillage) {
            GameManager.shared.updateVillage(mutableVillage)
            showToast("Built \(building.name)!")
            onUpdate()
        }
    }

    func quickRecruit(_ unitType: Unit.UnitType, quantity: Int) {
        var mutableVillage = village
        let units = recruitmentEngine.recruitUnits(
            unitType: unitType,
            quantity: quantity,
            in: &mutableVillage,
            at: village.coordinates
        )
        if !units.isEmpty {
            GameManager.shared.updateVillage(mutableVillage)
            showToast("Recruited \(units.count) \(unitType.rawValue)!")
            onUpdate()
        }
    }

    func showToast(_ message: String) {
        showMessage = message
        withAnimation(.spring(response: 0.3)) {
            showingMessage = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeOut) {
                showingMessage = false
            }
        }
    }

    // MARK: - Army Section
    var armySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("ARMY")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Spacer()
                if let army = armies.first {
                    Text("STR: \(army.strength)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }

            if armies.isEmpty {
                HStack {
                    Image(systemName: "shield.slash")
                        .foregroundColor(.secondary)
                    Text("No army - recruit soldiers above")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.cardBackground)
                .cornerRadius(8)
            } else if let army = armies.first {
                // Show unit composition
                let grouped = Dictionary(grouping: army.units, by: { $0.unitType })
                HStack(spacing: 12) {
                    ForEach(Array(grouped.keys), id: \.self) { type in
                        HStack(spacing: 4) {
                            Text(type.emoji)
                            Text("×\(grouped[type]?.count ?? 0)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.cardBackground)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }

    // MARK: - Buildings Section (BIGGER)
    var buildingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("BUILDINGS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(village.buildings.count)/\(village.maxBuildings)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if village.buildings.isEmpty {
                HStack {
                    Image(systemName: "hammer")
                        .foregroundColor(.secondary)
                    Text("No buildings - use Quick Build above")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.cardBackground)
                .cornerRadius(8)
            } else {
                VStack(spacing: 6) {
                    ForEach(village.buildings, id: \.id) { building in
                        BuildingRowCard(
                            building: building,
                            village: village,
                            onUpgrade: { buildingID in
                                upgradeBuilding(buildingID: buildingID)
                            }
                        )
                    }
                }
            }
        }
    }

    func upgradeBuilding(buildingID: UUID) {
        var mutableVillage = village
        if buildingEngine.upgradeBuilding(buildingID: buildingID, in: &mutableVillage) {
            GameManager.shared.updateVillage(mutableVillage)
            if let building = mutableVillage.buildings.first(where: { $0.id == buildingID }) {
                showToast("Upgraded \(building.name) to Lv.\(building.level)!")
            }
            onUpdate()
        }
    }

    func getBuildingEmoji(_ name: String) -> String {
        switch name {
        case "Farm": return "🌾"
        case "Lumber Mill": return "🪵"
        case "Iron Mine": return "⛏️"
        case "Market": return "🏪"
        case "Barracks": return "⚔️"
        case "Archery Range": return "🏹"
        case "Fortress": return "🏰"
        case "Temple": return "⛪"
        case "Granary": return "🏠"
        default: return "🏛️"
        }
    }

    // MARK: - Enemy Village Info
    var enemyVillageInfo: some View {
        let defenderArmies = GameManager.shared.getArmiesAt(villageID: village.id).filter { $0.owner == village.owner }
        let totalDefenders = defenderArmies.reduce(0) { $0 + $1.unitCount }
        let armyStrength = defenderArmies.reduce(0) { $0 + $1.strength }
        let garrisonValue = village.garrisonStrength * 3
        let totalStrength = armyStrength + garrisonValue

        return VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: village.owner == "neutral" ? "flag.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(village.owner == "neutral" ? .gray : .red)
                Text(village.owner == "neutral" ? "Neutral Territory" : "Enemy Territory")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)

            // Defense Summary - BIG AND CLEAR
            VStack(spacing: 12) {
                Text("DEFENSE STRENGTH")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("\(totalStrength)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.red)

                HStack(spacing: 20) {
                    VStack {
                        Text("\(village.garrisonStrength)")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Garrison")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    VStack {
                        Text("\(totalDefenders)")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Soldiers")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    VStack {
                        Text("+\(Int(village.defenseBonus * 100))%")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Bonus")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)

            // Recommendation
            let playerArmies = GameManager.shared.getArmiesFor(playerID: "player")
            let playerStrength = playerArmies.reduce(0) { $0 + $1.strength }
            let recommended = Int(Double(totalStrength) * 1.2)
            let canWin = playerStrength >= recommended

            HStack {
                Image(systemName: canWin ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(canWin ? .green : .orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(canWin ? "You can attack!" : "Build more army")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Your strength: \(playerStrength) / Need: ~\(recommended)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(canWin ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
    }
}

// MARK: - Quick Build Button (with cost display)

struct QuickBuildButton: View {
    let icon: String
    let name: String
    let building: Building
    let village: Village
    let onBuild: () -> Void

    let buildingEngine = BuildingConstructionEngine()

    var canBuild: Bool {
        buildingEngine.canBuild(building: building, in: village).can
    }

    var alreadyBuilt: Bool {
        village.buildings.contains { $0.name == building.name }
    }

    var costString: String {
        // Show primary cost (gold)
        if let gold = building.baseCost[.gold] {
            return "\(gold)g"
        }
        return ""
    }

    var body: some View {
        Button(action: onBuild) {
            VStack(spacing: 2) {
                ZStack {
                    Text(icon)
                        .font(.title3)
                    // Checkmark overlay if already built
                    if alreadyBuilt {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                            .offset(x: 12, y: -8)
                    }
                }
                Text(name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .lineLimit(1)
                // Show cost if not built
                if !alreadyBuilt {
                    Text(costString)
                        .font(.system(size: 9))
                        .foregroundColor(canBuild ? .green : .red)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                alreadyBuilt ? Color.green.opacity(0.15) :
                canBuild ? Color.green.opacity(0.2) : Color.cardBackground
            )
            .foregroundColor(alreadyBuilt ? .green : (canBuild ? .white : .secondary))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(canBuild && !alreadyBuilt ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!canBuild || alreadyBuilt)
        .help(alreadyBuilt ? "\(name) already built" : buildingEngine.canBuild(building: building, in: village).reason)
    }
}

// MARK: - Compact Recruit Button (inline)

struct CompactRecruitButton: View {
    let emoji: String
    let count: Int
    let unitType: Unit.UnitType
    let village: Village
    let onRecruit: () -> Void

    let recruitmentEngine = RecruitmentEngine()

    var recruitCheck: (can: Bool, reason: String) {
        recruitmentEngine.canRecruit(unitType: unitType, quantity: count, in: village)
    }

    var canRecruit: Bool { recruitCheck.can }

    var unitCost: Int {
        let stats = Unit.getStats(for: unitType)
        return (stats.cost[.gold] ?? 0) * count
    }

    var body: some View {
        Button(action: onRecruit) {
            VStack(spacing: 1) {
                HStack(spacing: 2) {
                    Text(emoji)
                        .font(.caption)
                    Text("×\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                Text("\(unitCost)g")
                    .font(.system(size: 8))
                    .foregroundColor(canRecruit ? .cyan : .secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(canRecruit ? Color.blue.opacity(0.3) : Color.cardBackground)
            .foregroundColor(canRecruit ? .white : .secondary)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .disabled(!canRecruit)
        .help(canRecruit ? "\(unitType.rawValue.capitalized) (\(unitCost)g) - \(unitType.counterInfo)" : recruitCheck.reason)
    }
}

// MARK: - Building Row Card (detailed with upgrade)

struct BuildingRowCard: View {
    let building: Building
    let village: Village
    let onUpgrade: (UUID) -> Void

    let buildingEngine = BuildingConstructionEngine()

    var emoji: String {
        switch building.name {
        case "Farm": return "🌾"
        case "Lumber Mill": return "🪵"
        case "Iron Mine": return "⛏️"
        case "Market": return "🏪"
        case "Barracks": return "⚔️"
        case "Archery Range": return "🏹"
        case "Fortress": return "🏰"
        case "Temple": return "⛪"
        case "Granary": return "🏠"
        case "Aqueduct": return "🚰"
        default: return "🏛️"
        }
    }

    var productionText: String? {
        if let prod = building.resourcesProduction.first {
            return "+\(prod.value) \(prod.key.emoji)"
        }
        return nil
    }

    var bonusText: String? {
        if building.defenseBonus > 0 {
            return "+\(Int(building.defenseBonus * 100))% DEF"
        }
        if building.happinessBonus > 0 {
            return "+\(building.happinessBonus) 😊"
        }
        return nil
    }

    var upgradeCheck: (can: Bool, cost: [Resource: Int], reason: String) {
        buildingEngine.canUpgradeBuilding(building, in: village)
    }

    var upgradeCostString: String {
        if let gold = upgradeCheck.cost[.gold] {
            return "\(gold)g"
        }
        return ""
    }

    var body: some View {
        HStack(spacing: 10) {
            // Emoji
            Text(emoji)
                .font(.title3)
                .frame(width: 32)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(building.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("Lv.\(building.level)")
                        .font(.system(size: 9))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(4)
                }

                HStack(spacing: 6) {
                    if let prod = productionText {
                        Text(prod)
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    if let bonus = bonusText {
                        Text(bonus)
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            // Upgrade button
            if building.level < 5 {
                Button(action: { onUpgrade(building.id) }) {
                    VStack(spacing: 1) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.caption)
                        Text(upgradeCostString)
                            .font(.system(size: 8))
                    }
                    .foregroundColor(upgradeCheck.can ? .green : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(upgradeCheck.can ? Color.green.opacity(0.2) : Color.cardBackground)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(!upgradeCheck.can)
                .help(upgradeCheck.can ? "Upgrade to level \(building.level + 1)" : upgradeCheck.reason)
            } else {
                Text("MAX")
                    .font(.caption2)
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(8)
        .background(Color.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.3) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(10)
    }
}

struct DefenseRow: View {
    let icon: String
    let label: String
    let value: String
    let strength: Int

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.red.opacity(0.8))
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
            if strength > 0 {
                Text("(\(strength))")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Army Card

struct ArmyCard: View {
    let army: Army
    let onSend: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(army.emoji)
                    .font(.title)

                VStack(alignment: .leading, spacing: 2) {
                    Text(army.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    // Unit composition icons
                    let grouped = Dictionary(grouping: army.units, by: { $0.unitType })
                    HStack(spacing: 4) {
                        ForEach(Array(grouped.keys), id: \.self) { type in
                            HStack(spacing: 2) {
                                Text(type.emoji)
                                    .font(.caption2)
                                Text("×\(grouped[type]?.count ?? 0)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Spacer()

                Button(action: onSend) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Send")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            // Combat stats bar
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "burst.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("\(army.totalAttack)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                HStack(spacing: 4) {
                    Image(systemName: "shield.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text("\(army.totalDefense)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                Spacer()

                Text("STR: \(army.strength)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Army Panel (for selected marching armies)

struct ArmyPanel: View {
    let army: Army

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Marching status
            if army.isMarching {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.orange)
                        Text("On the march")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                    }

                    if let destID = army.destination,
                       let dest = GameManager.shared.map.villages.first(where: { $0.id == destID }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Destination")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                HStack {
                                    Text(dest.nationality.flag)
                                    Text(dest.name)
                                        .fontWeight(.medium)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Arrives in")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(army.turnsUntilArrival) turns")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }

            // Unit breakdown with counter info
            VStack(alignment: .leading, spacing: 8) {
                Text("Unit Composition")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                let grouped = Dictionary(grouping: army.units, by: { $0.unitType })
                ForEach(Array(grouped.keys), id: \.self) { type in
                    HStack {
                        Text(type.emoji)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(type.rawValue.capitalized)
                                .font(.subheadline)
                            Text(type.counterInfo)
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        Spacer()
                        Text("×\(grouped[type]?.count ?? 0)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)

            // Stats
            HStack(spacing: 20) {
                VStack {
                    Text("\(army.totalAttack)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Attack")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack {
                    Text("\(army.totalDefense)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Defense")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack {
                    Text("\(army.totalHP)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("HP")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack {
                    Text("\(army.strength)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Total Strength")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
        .padding()
    }
}

// MARK: - Empire Overview Panel

struct EmpireOverviewPanel: View {
    @ObservedObject var gameManager = GameManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Empire stats
            let villages = gameManager.getPlayerVillages(playerID: "player")
            let armies = gameManager.getArmiesFor(playerID: "player")
            let totalPop = villages.reduce(0) { $0 + $1.population }
            let totalSoldiers = armies.reduce(0) { $0 + $1.unitCount }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                EmpireStatCard(icon: "building.2.fill", value: "\(villages.count)", label: "Villages", color: .purple)
                EmpireStatCard(icon: "person.3.fill", value: "\(totalPop)", label: "Population", color: .blue)
                EmpireStatCard(icon: "shield.fill", value: "\(armies.count)", label: "Armies", color: .green)
                EmpireStatCard(icon: "figure.stand", value: "\(totalSoldiers)", label: "Soldiers", color: .orange)
            }

            Divider()

            // Villages list
            VStack(alignment: .leading, spacing: 8) {
                Text("YOUR VILLAGES")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                ForEach(villages, id: \.id) { village in
                    HStack {
                        Text(village.nationality.flag)
                        Text(village.name)
                            .font(.subheadline)
                        Spacer()
                        Text("\(village.population)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Image(systemName: "person.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .background(Color.cardBackground)
                    .cornerRadius(8)
                }
            }

            Divider()

            // Armies list
            VStack(alignment: .leading, spacing: 8) {
                Text("YOUR ARMIES")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                if armies.isEmpty {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Build a Barracks to recruit soldiers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.cardBackground)
                    .cornerRadius(8)
                } else {
                    ForEach(armies, id: \.id) { army in
                        HStack {
                            Text(army.emoji)
                            Text(army.name)
                                .font(.subheadline)
                            Spacer()
                            if army.isMarching {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.right")
                                        .font(.caption2)
                                    Text("\(army.turnsUntilArrival)t")
                                        .font(.caption)
                                }
                                .foregroundColor(.orange)
                            } else {
                                Text("\(army.unitCount) units")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(8)
                        .background(Color.cardBackground)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
    }
}

struct EmpireStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Send Army Sheet

struct SendArmySheet: View {
    let army: Army
    let currentVillage: Village
    let onSend: (Village) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Deploy Army")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(army.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.cardBackground)

            // Targets - ONLY VISIBLE VILLAGES (fog of war)
            ScrollView {
                VStack(spacing: 8) {
                    let visibleVillages = GameManager.shared.getVisibleVillages(for: "player")
                    let targets = visibleVillages.filter { $0.id != currentVillage.id }
                    let sorted = targets.sorted { v1, v2 in
                        let d1 = Army.calculateTravelTime(from: currentVillage.coordinates, to: v1.coordinates)
                        let d2 = Army.calculateTravelTime(from: currentVillage.coordinates, to: v2.coordinates)
                        return d1 < d2
                    }

                    ForEach(sorted, id: \.id) { target in
                        DestinationCard(
                            target: target,
                            currentVillage: currentVillage,
                            army: army,
                            onSelect: {
                                onSend(target)
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .frame(width: 450, height: 550)
        .background(Color.panelBackground)
    }
}

struct DestinationCard: View {
    let target: Village
    let currentVillage: Village
    let army: Army
    let onSelect: () -> Void

    var turns: Int {
        Army.calculateTravelTime(from: currentVillage.coordinates, to: target.coordinates)
    }

    var isEnemy: Bool {
        target.owner != "player"
    }

    // BATTLE PREDICTION
    var defenderStrength: Int {
        let defenders = GameManager.shared.getArmiesAt(villageID: target.id).filter { $0.owner == target.owner }
        let armyStr = defenders.reduce(0) { $0 + $1.strength }
        let garrisonStr = target.garrisonStrength * 3
        let popStr = target.population / 10
        return armyStr + garrisonStr + popStr
    }

    var attackerStrength: Int {
        army.strength
    }

    var winChance: Int {
        guard defenderStrength > 0 else { return 100 }
        let ratio = Double(attackerStrength) / Double(defenderStrength)
        // Simple win chance calculation
        if ratio >= 2.0 { return 95 }
        if ratio >= 1.5 { return 80 }
        if ratio >= 1.2 { return 65 }
        if ratio >= 1.0 { return 50 }
        if ratio >= 0.8 { return 35 }
        if ratio >= 0.5 { return 20 }
        return 10
    }

    var winChanceColor: Color {
        if winChance >= 70 { return .green }
        if winChance >= 40 { return .yellow }
        return .red
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Flag and name
                Text(target.nationality.flag)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(target.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                            Text("\(turns)t")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)

                        if isEnemy {
                            Text("•")
                                .foregroundColor(.secondary)
                            HStack(spacing: 2) {
                                Text("\(attackerStrength)")
                                    .foregroundColor(.green)
                                Text("vs")
                                    .foregroundColor(.secondary)
                                Text("\(defenderStrength)")
                                    .foregroundColor(.red)
                            }
                            .font(.caption2)
                        }
                    }
                }

                Spacer()

                // Battle prediction
                if isEnemy {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(winChance)%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(winChanceColor)
                        Text("win")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 50)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isEnemy ? winChanceColor.opacity(0.4) : Color.green.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
