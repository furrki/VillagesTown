//
//  MobileGameLayout.swift
//  VillagesTown
//
//  Full-screen map with bottom sheet for mobile devices
//

import SwiftUI

struct MobileGameLayout: View {
    @ObservedObject var gameManager = GameManager.shared
    @State private var selectedVillage: Village?
    @State private var selectedArmy: Army?
    @State private var isProcessingTurn = false
    @State private var isSpectating = false
    @State private var showGameEndScreen = true
    @State private var toastEvents: [TurnEvent] = []
    @State private var mapScale: CGFloat = 1.0
    @State private var mapOffset: CGSize = .zero
    
    // Smooth zoom state
    @GestureState private var magnificationState: CGFloat = 1.0
    
    var winner: Player? {
        let activePlayers = gameManager.players.filter { !$0.isEliminated }
        return activePlayers.count == 1 ? activePlayers.first : nil
    }

    var playerEliminated: Bool {
        gameManager.players.first(where: { $0.isHuman })?.isEliminated ?? false
    }

    var body: some View {
        ZStack {
            Color.mapBackground.ignoresSafeArea()

            // Full-screen strategic map
            strategicMapView
                .ignoresSafeArea()

            // Floating HUD (top)
            VStack {
                FloatingHUD(
                    turn: gameManager.currentTurn,
                    resources: gameManager.getGlobalResources(playerID: "player"),
                    playerVillages: gameManager.getPlayerVillages(playerID: "player").count,
                    totalVillages: gameManager.map.villages.count
                )
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()
            }
            // Allow touches to pass through to map
            .allowsHitTesting(false) 
            
            // HUD needs hits for scrollview though... wrap in clear background?
            // Actually FloatingHUD has buttons? No, just info.
            // Wait, ScrollView in FloatingHUD needs touch. 
            // We should just restrict hit testing to the HUD area.
            
            // Toast notifications
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
            .padding(.top, 100)
            .allowsHitTesting(false)

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

            // Spectator indicator
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
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .foregroundColor(.primary)
                        .shadow(radius: 4)
                        Spacer()
                    }
                    .padding()
                    .padding(.top, 60)
                    Spacer()
                }
            }
        }
        .sheet(isPresented: .constant(true)) {
            GameBottomSheet(
                selectedVillage: $selectedVillage,
                selectedArmy: $selectedArmy,
                isProcessingTurn: $isProcessingTurn,
                onEndTurn: processTurn
            )
            .presentationDetents([
                .height(130),
                .fraction(0.40),
                .large
            ])
            .presentationDragIndicator(.visible)
            .modifier(BackgroundInteractionModifier())
            .interactiveDismissDisabled()
            .edgesIgnoringSafeArea(.bottom) // Extend background
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if !gameManager.gameStarted {
                gameManager.initializeGame()
            }
            if selectedVillage == nil {
                selectedVillage = gameManager.getPlayerVillages(playerID: "player").first
            }
        }
    }

    // MARK: - Strategic Map

    var visibleVillages: [Village] {
        gameManager.getVisibleVillages(for: "player")
    }

    var visibleArmies: [Army] {
        gameManager.getVisibleArmies(for: "player")
    }

    var strategicMapView: some View {
        GeometryReader { geometry in
            ZStack {
                MapBackgroundView()

                // Army movement paths
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

                // Village connections
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
                            Color.white.opacity(0.1),
                            style: StrokeStyle(lineWidth: 2, dash: [4, 4])
                        )
                    }
                }

                // Fogged villages
                ForEach(gameManager.map.villages.filter { village in
                    !visibleVillages.contains { $0.id == village.id }
                }, id: \.id) { village in
                    FoggedVillageView()
                        .position(villagePosition(village, in: geometry.size))
                }

                // Marching armies
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
                            LayoutConstants.selectionFeedback()
                            withAnimation(.spring(response: 0.3)) {
                                selectedArmy = army
                                selectedVillage = nil
                            }
                        }
                    }
                }

                // Villages
                ForEach(visibleVillages, id: \.id) { village in
                    let armies = gameManager.getArmiesAt(villageID: village.id).filter { $0.owner == village.owner }
                    let armyStrength = armies.reduce(0) { $0 + $1.strength }
                    let allUnits = armies.flatMap { $0.units }

                    MobileVillageNode(
                        village: village,
                        isSelected: selectedVillage?.id == village.id,
                        armyCount: armies.first?.unitCount ?? 0,
                        armyStrength: armyStrength,
                        unitComposition: allUnits,
                        hasIncomingThreat: hasIncomingThreat(to: village)
                    )
                    .position(villagePosition(village, in: geometry.size))
                    .onTapGesture {
                        LayoutConstants.selectionFeedback()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedVillage = village
                            selectedArmy = nil
                        }
                    }
                }
            }
            .scaleEffect(mapScale * magnificationState)
            .offset(mapOffset)
            .gesture(
                SimultaneousGesture(
                    MagnificationGesture()
                        .updating($magnificationState) { currentState, gestureState, _ in
                            gestureState = currentState
                        }
                        .onEnded { value in
                            mapScale = min(max(mapScale * value, 0.5), 3.0)
                        },
                    DragGesture()
                        .onChanged { value in
                            mapOffset = CGSize(
                                width: mapOffset.width + value.translation.width * 0.1, // dampen drag
                                height: mapOffset.height + value.translation.height * 0.1
                            )
                        }
                        .onEnded { value in
                             mapOffset = CGSize(
                                width: mapOffset.width + value.translation.width,
                                height: mapOffset.height + value.translation.height
                             )
                        }
                )
            )
        }
    }

    // MARK: - Helper Functions

    func getConnectedVillages(for village: Village) -> [Village] {
        gameManager.map.villages.filter { other in
            guard other.id != village.id else { return false }
            let dist = distance(from: village.coordinates, to: other.coordinates)
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
        // Use more of the screen space on mobile
        let mapWidth = CGFloat(gameManager.map.size.width)
        let mapHeight = CGFloat(gameManager.map.size.height)
        
        // Add dynamic padding based on screen size to keep villages away from edges
        let paddingX = size.width * 0.15
        let paddingY = size.height * 0.20 // detailed top/bottom bars need clearance

        let x = paddingX + (village.coordinates.x / mapWidth) * (size.width - paddingX * 2)
        let y = paddingY + (village.coordinates.y / mapHeight) * (size.height - paddingY * 2)

        return CGPoint(x: x, y: y)
    }

    func calculateMarchProgress(army: Army, from origin: Village, to destination: Village) -> CGFloat {
        let totalTurns = Army.calculateTravelTime(from: origin.coordinates, to: destination.coordinates)
        let remaining = army.turnsUntilArrival
        return CGFloat(totalTurns - remaining) / CGFloat(max(totalTurns, 1))
    }

    func processTurn() {
        withAnimation(.spring(response: 0.3)) {
            isProcessingTurn = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            gameManager.turnEngine.doTurn()
            refreshSelection()

            let events = gameManager.turnEvents
            showToasts(for: events)

            withAnimation(.spring(response: 0.3)) {
                isProcessingTurn = false
            }

            gameManager.objectWillChange.send()
        }
    }

    func showToasts(for events: [TurnEvent]) {
        let importantEvents = events.filter { $0.isImportant }
        for (index, event) in importantEvents.prefix(3).enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.3) {
                withAnimation(.spring(response: 0.4)) {
                    toastEvents.append(event)
                }
            }
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
}

// MARK: - Mobile Village Node (Modern Pill Design)

struct MobileVillageNode: View {
    let village: Village
    let isSelected: Bool
    let armyCount: Int
    let armyStrength: Int
    let unitComposition: [Unit]
    let hasIncomingThreat: Bool

    @State private var pulseAnimation = false

    var ownerColor: Color {
        switch village.owner {
        case "player": return .blue
        case "ai1": return .ai1Color
        case "ai2": return .ai2Color
        case "neutral": return .neutralGray
        default: return .gray
        }
    }

    var body: some View {
        ZStack {
            // Context glow
            if isSelected {
                Circle()
                    .fill(ownerColor.opacity(0.4))
                    .frame(width: 90, height: 90)
                    .blur(radius: 12)
            }
            
            // Threat pulse
            if hasIncomingThreat {
                Circle()
                    .stroke(Color.red, lineWidth: 2)
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .opacity(pulseAnimation ? 0 : 0.8)
                    .onAppear {
                        withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                            pulseAnimation = true
                        }
                    }
            }

            // Main Pill
            VStack(spacing: 0) {
                // Top Half: Flag and Name
                VStack(spacing: 2) {
                    Text(village.nationality.flag)
                        .font(.system(size: 24))
                    Text(village.name)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(width: 70, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? ownerColor : Color.black.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(ownerColor, lineWidth: 2)
                        )
                )

                // Bottom Half: Stats (if relevant)
                if armyCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 8))
                        Text("\(armyStrength)")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue)
                    .clipShape(Capsule())
                    .offset(y: -8) // Overlap slightly
                }
            }
        }
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
        .shadow(color: .black.opacity(0.4), radius: 6, y: 4)
    }
}

struct BackgroundInteractionModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationBackgroundInteraction(.enabled)
        } else {
            content
        }
    }
}

