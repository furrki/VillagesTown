//
//  GameView.swift
//  VillagesTown
//
//  Completely redesigned UX - side panel instead of modal sheets
//

import SwiftUI

struct GameView: View {
    @ObservedObject var gameManager = GameManager.shared
    @State private var selectedVillage: Village?
    @State private var selectedUnit: Unit?
    @State private var showVictoryScreen = false
    @State private var isProcessingTurn = false
    @State private var showTutorial = true
    @State private var showSidePanel = true

    var winner: Player? {
        let activePlayers = gameManager.players.filter { !$0.isEliminated }
        return activePlayers.count == 1 ? activePlayers.first : nil
    }

    var body: some View {
        HStack(spacing: 0) {
            // LEFT: Map + Controls (always visible)
            VStack(spacing: 0) {
                // Top Bar
                topBar

                // Map
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    MapView_Interactive(
                        selectedVillage: $selectedVillage,
                        selectedUnit: $selectedUnit
                    )
                    .frame(
                        width: CGFloat(gameManager.map.size.width) * 25,
                        height: CGFloat(gameManager.map.size.height) * 25
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Bottom Control Panel
                bottomBar
            }
            .frame(maxWidth: .infinity)

            // RIGHT: Side Panel (persistent)
            if showSidePanel {
                sidePanelContent
                    .frame(width: 350)
                    .transition(.move(edge: .trailing))
            }
        }
        .onAppear {
            if !gameManager.gameStarted {
                gameManager.initializeGame()
            }
        }
        .overlay(
            Group {
                if let winner = winner, showVictoryScreen {
                    VictoryScreenView(winner: winner, turns: gameManager.currentTurn, isPresented: $showVictoryScreen)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        )
        .overlay(
            Group {
                if showTutorial && gameManager.currentTurn == 1 && gameManager.tutorialEnabled {
                    TutorialOverlay(isPresented: $showTutorial)
                        .transition(.opacity.combined(with: .scale))
                }
            }
        )
        .onChange(of: gameManager.currentTurn) { _ in
            if winner != nil {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showVictoryScreen = true
                }
            }
        }
    }

    var sidePanelContent: some View {
        VStack(spacing: 0) {
            // Panel Header
            HStack {
                Text(selectedVillage?.name ?? "Your Empire")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showSidePanel = false
                    }
                }) {
                    Image(systemName: "sidebar.right")
                        .font(.title3)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Panel Content
            if let village = selectedVillage {
                ScrollView {
                    VillageDetailPanel(village: village, onUpdate: {
                        // Refresh village
                        if let coords = selectedVillage?.coordinates {
                            selectedVillage = gameManager.map.getVillageAt(
                                x: Int(coords.x),
                                y: Int(coords.y)
                            )
                        }
                    })
                }
            } else {
                // Show all player units when no village selected
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // Player Units Section
                        playerUnitsSection

                        Divider()

                        // Quick village list
                        playerVillagesSection
                    }
                    .padding()
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }

    var playerUnitsSection: some View {
        let playerUnits = gameManager.map.units.filter { $0.owner == "player" }

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Your Units")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(playerUnits.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if playerUnits.isEmpty {
                Text("No units recruited yet.\nBuild a Barracks and recruit soldiers!")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(playerUnits) { unit in
                    HStack(spacing: 8) {
                        Text(unit.unitType.emoji)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(unit.name)
                                .font(.caption)
                                .fontWeight(.medium)
                            HStack(spacing: 6) {
                                HStack(spacing: 2) {
                                    Image(systemName: "heart.fill").font(.system(size: 8)).foregroundColor(.red)
                                    Text("\(unit.currentHP)/\(unit.maxHP)").font(.system(size: 9))
                                }
                                HStack(spacing: 2) {
                                    Image(systemName: "figure.walk").font(.system(size: 8)).foregroundColor(.blue)
                                    Text("\(unit.movementRemaining)/\(unit.movement)").font(.system(size: 9))
                                }
                            }
                            .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("(\(Int(unit.coordinates.x)),\(Int(unit.coordinates.y)))")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .padding(6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                }
            }
        }
    }

    var playerVillagesSection: some View {
        let playerVillages = gameManager.getPlayerVillages(playerID: "player")

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Your Villages")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(playerVillages.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(playerVillages, id: \.id) { village in
                Button(action: {
                    selectedVillage = village
                }) {
                    HStack(spacing: 8) {
                        Text(village.nationality.flag)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(village.name)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("\(village.population) pop • \(village.buildings.count) buildings")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    var topBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Turn \(gameManager.currentTurn)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)

                Spacer()

                let enemyVillages = gameManager.map.villages.filter { $0.owner != "player" }
                VStack(spacing: 2) {
                    Text("🎯 Conquer all enemy villages")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("Enemies: \(enemyVillages.count) remaining")
                        .font(.caption2)
                        .foregroundColor(enemyVillages.isEmpty ? .green : .orange)
                }

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showSidePanel.toggle()
                    }
                }) {
                    Image(systemName: showSidePanel ? "sidebar.right" : "sidebar.left")
                        .font(.title2)
                }
            }
            .padding(.horizontal)

            // Resources
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    let globalResources = gameManager.getGlobalResources(playerID: "player")
                    ForEach(Resource.getAll(), id: \.self) { resource in
                        ResourceBadge(resource: resource, amount: globalResources[resource] ?? 0)
                    }
                }
                .padding(.horizontal)
            }

            // Stats
            HStack(spacing: 20) {
                let playerVillages = gameManager.getPlayerVillages(playerID: "player")
                let totalPop = playerVillages.reduce(0) { $0 + $1.population }
                let avgHappiness = playerVillages.isEmpty ? 0 : playerVillages.reduce(0) { $0 + $1.totalHappiness } / playerVillages.count
                let playerUnits = gameManager.map.units.filter { $0.owner == "player" }

                Label("\(totalPop)", systemImage: "person.3.fill")
                Label("\(avgHappiness)%", systemImage: happinessIcon(for: avgHappiness))
                Label("\(playerVillages.count) Villages", systemImage: "house.fill")
                Label("\(playerUnits.count) Units", systemImage: "figure.walk")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
        .shadow(radius: 2)
    }

    var bottomBar: some View {
        HStack(spacing: 16) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isProcessingTurn = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    gameManager.turnEngine.doTurn()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isProcessingTurn = false
                    }
                }
            }) {
                HStack {
                    Image(systemName: isProcessingTurn ? "hourglass" : "arrow.right.circle.fill")
                        .font(.title2)
                    Text(isProcessingTurn ? "Processing..." : "Next Turn")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(isProcessingTurn ? Color.orange : Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isProcessingTurn)

            Spacer()
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .shadow(radius: 2)
    }

    func happinessIcon(for happiness: Int) -> String {
        if happiness >= 80 { return "face.smiling.fill" }
        if happiness >= 50 { return "face.smiling" }
        return "face.dashed.fill"
    }
}

// Simplified village detail panel (not a modal)
struct VillageDetailPanel: View {
    let village: Village
    let onUpdate: () -> Void
    @State private var showBuildSection = true
    @State private var showRecruitSection = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Village Info
            villageHeader

            Divider()

            // Resources
            resourcesSection

            Divider()

            // Buildings
            buildingsSection

            Divider()

            // Build Section
            buildSection

            Divider()

            // Recruit Section
            recruitSection
        }
        .padding()
    }

    var villageHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(village.nationality.flag).font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(village.name).font(.subheadline).fontWeight(.bold)
                    Text(village.level.displayName).font(.caption2).foregroundColor(.secondary)
                }
            }

            HStack(spacing: 12) {
                CompactStat(icon: "person.3.fill", value: "\(village.population)/\(village.populationCapacity)")
                CompactStat(icon: "face.smiling", value: "\(village.totalHappiness)%")
                CompactStat(icon: "shield.fill", value: "+\(Int(village.defenseBonus * 100))%")
            }
        }
    }

    var resourcesSection: some View {
        let globalResources = GameManager.shared.getGlobalResources(playerID: village.owner)
        return VStack(alignment: .leading, spacing: 4) {
            Text("Resources").font(.caption).fontWeight(.semibold)
            HStack(spacing: 8) {
                ForEach(Resource.getAll(), id: \.self) { resource in
                    HStack(spacing: 2) {
                        Text(resource.emoji).font(.caption2)
                        Text("\(globalResources[resource] ?? 0)").font(.caption2).fontWeight(.medium)
                    }
                }
            }
        }
    }

    var buildingsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Buildings").font(.caption).fontWeight(.semibold)
                let upgradeableCount = village.buildings.filter { building in
                    BuildingConstructionEngine().canUpgradeBuilding(building, in: village).can
                }.count
                if upgradeableCount > 0 {
                    Text("\(upgradeableCount) upgradeable")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
                Spacer()
                Text("\(village.buildings.count)/\(village.maxBuildings)").font(.caption2).foregroundColor(.secondary)
            }

            if village.buildings.isEmpty {
                Text("No buildings yet").foregroundColor(.secondary).italic().font(.caption2)
            } else {
                ForEach(village.buildings) { building in
                    BuildingCardSimple(building: building, village: village, onUpgrade: { buildingID in
                        var mutableVillage = village
                        let engine = BuildingConstructionEngine()
                        if engine.upgradeBuilding(buildingID: buildingID, in: &mutableVillage) {
                            GameManager.shared.updateVillage(mutableVillage)
                            onUpdate()
                        }
                    })
                }
            }
        }
    }

    var buildSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showBuildSection.toggle()
                }
            }) {
                HStack {
                    Text("Build").font(.caption).fontWeight(.semibold)
                    Spacer()
                    Image(systemName: showBuildSection ? "chevron.up" : "chevron.down").font(.caption2)
                }
            }
            .buttonStyle(.plain)

            if showBuildSection {
                BuildMenuInlineView(village: village, onUpdate: onUpdate)
            }
        }
    }

    var recruitSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showRecruitSection.toggle()
                }
            }) {
                HStack {
                    Text("Recruit").font(.caption).fontWeight(.semibold)
                    Spacer()
                    Image(systemName: showRecruitSection ? "chevron.up" : "chevron.down").font(.caption2)
                }
            }
            .buttonStyle(.plain)

            if showRecruitSection {
                RecruitMenuInlineView(village: village, onUpdate: onUpdate)
            }
        }
    }
}

// New interactive map view (no modal sheets)
struct MapView_Interactive: View {
    @ObservedObject var viewModel: MapViewModel = MapViewModel(map: GameManager.shared.map)
    @Binding var selectedVillage: Village?
    @Binding var selectedUnit: Unit?
    @State private var selectedUnitsForMovement: [Unit] = []
    @State private var validMovementTiles: Set<String> = []
    @State private var showAttackConfirmation = false
    @State private var attackTarget: Village?
    @State private var attackResult: String = ""
    @State private var showAttackResult = false

    var body: some View {
        VStack(alignment: .center, spacing: 2.0) {
            ForEach((0...self.viewModel.getMapHeight()), id: \.self) { y in
                HStack(alignment: .center, spacing: 2.0) {
                    ForEach((0...self.viewModel.getMapWidth()), id: \.self) { x in
                        MapTile(
                            x: x,
                            y: y,
                            viewModel: viewModel,
                            isSelected: isSelectedTile(x: x, y: y),
                            isValidMove: validMovementTiles.contains("\(x),\(y)"),
                            onTap: {
                                handleTileTap(x: x, y: y)
                            }
                        )
                    }
                }
            }
        }
        .alert("Attack Village?", isPresented: $showAttackConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Attack", role: .destructive) {
                executeAttack()
            }
        } message: {
            if let target = attackTarget {
                Text("Attack \(target.name)?")
            }
        }
        .alert("Battle Result", isPresented: $showAttackResult) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(attackResult)
        }
    }

    func handleTileTap(x: Int, y: Int) {
        let destination = CGPoint(x: x, y: y)

        // 1. If units are already selected → try to move/attack
        if !selectedUnitsForMovement.isEmpty {
            // Check if destination is a valid move
            if validMovementTiles.contains("\(x),\(y)") {
                // Move ALL selected units to destination
                var mutableMap = GameManager.shared.map
                let movementEngine = MovementEngine()

                for unit in selectedUnitsForMovement {
                    var mutableUnit = unit
                    _ = movementEngine.moveUnit(unit: &mutableUnit, to: destination, map: &mutableMap)
                }

                GameManager.shared.map = mutableMap
                selectedUnitsForMovement.removeAll()
                validMovementTiles.removeAll()
                NotificationCenter.default.post(name: NSNotification.Name("MapUpdated"), object: nil)
                return
            }

            // Check if tapping enemy village for attack
            if let village = viewModel.getVillageAt(x: x, y: y), village.owner != "player" {
                if let firstUnit = selectedUnitsForMovement.first {
                    let unitX = Int(firstUnit.coordinates.x)
                    let unitY = Int(firstUnit.coordinates.y)
                    let distance = max(abs(x - unitX), abs(y - unitY))

                    if distance <= 1 {
                        attackTarget = village
                        showAttackConfirmation = true
                        return
                    }
                }
            }

            // Clear selection if tapping elsewhere
            selectedUnitsForMovement.removeAll()
            validMovementTiles.removeAll()
        }

        // 2. Check for player units on this tile FIRST (priority over village)
        let units = viewModel.getUnitsAt(x: x, y: y)
        let playerUnits = units.filter { $0.owner == "player" }

        if !playerUnits.isEmpty {
            // SELECT ALL PLAYER UNITS on this tile
            selectedUnitsForMovement = playerUnits
            calculateValidMovementTiles(for: playerUnits)
            return
        }

        // 3. Only check for village if no player units
        if let village = viewModel.getVillageAt(x: x, y: y) {
            selectedVillage = village
            return
        }
    }

    func isSelectedTile(x: Int, y: Int) -> Bool {
        guard let firstUnit = selectedUnitsForMovement.first else { return false }
        return Int(firstUnit.coordinates.x) == x && Int(firstUnit.coordinates.y) == y
    }

    func calculateValidMovementTiles(for units: [Unit]) {
        validMovementTiles.removeAll()
        guard let firstUnit = units.first else { return }

        let movementEngine = MovementEngine()
        // Use minimum movement among all selected units
        let minMovement = units.map { $0.movementRemaining }.min() ?? 0
        let unitX = Int(firstUnit.coordinates.x)
        let unitY = Int(firstUnit.coordinates.y)

        for dx in -minMovement...minMovement {
            for dy in -minMovement...minMovement {
                let x = unitX + dx
                let y = unitY + dy
                if dx == 0 && dy == 0 { continue }
                let destination = CGPoint(x: x, y: y)
                // Check if ALL units can move there
                let allCanMove = units.allSatisfy { unit in
                    movementEngine.canMoveTo(unit: unit, destination: destination, map: GameManager.shared.map).can
                }
                if allCanMove {
                    validMovementTiles.insert("\(x),\(y)")
                }
            }
        }
    }

    func executeAttack() {
        guard let target = attackTarget,
              let firstUnit = selectedUnitsForMovement.first else {
            return
        }

        var attackers = GameManager.shared.map.getUnitsAt(point: firstUnit.coordinates)
            .filter { $0.owner == "player" }
        var defenders = GameManager.shared.map.getUnitsAt(point: target.coordinates)
            .filter { $0.owner == target.owner }

        let combatEngine = CombatEngine()
        let result = combatEngine.resolveCombat(
            attackers: &attackers,
            defenders: &defenders,
            location: target.coordinates,
            map: GameManager.shared.map,
            defendingVillage: target
        )

        for attacker in attackers {
            GameManager.shared.map.updateUnit(attacker)
        }
        for defender in defenders {
            GameManager.shared.map.updateUnit(defender)
        }

        if result.attackerWon && defenders.isEmpty {
            var mutableTarget = target
            mutableTarget.owner = "player"
            mutableTarget.population = Int(Double(mutableTarget.population) * 0.7)
            mutableTarget.happiness -= 30
            GameManager.shared.updateVillage(mutableTarget)
            attackResult = "🎉 \(target.name) conquered!\nLost: \(result.attackerCasualties), Killed: \(result.defenderCasualties)"
        } else if result.attackerWon {
            attackResult = "✅ Victory!\nLost: \(result.attackerCasualties), Killed: \(result.defenderCasualties)"
        } else {
            attackResult = "❌ Defeat!\nLost: \(result.attackerCasualties), Killed: \(result.defenderCasualties)"
        }

        selectedUnitsForMovement.removeAll()
        validMovementTiles.removeAll()
        attackTarget = nil
        showAttackResult = true
        NotificationCenter.default.post(name: NSNotification.Name("MapUpdated"), object: nil)
    }
}

struct ResourceBadge: View {
    let resource: Resource
    let amount: Int
    @State private var previousAmount: Int = 0
    @State private var isChanged = false

    var body: some View {
        VStack(spacing: 4) {
            Text(resource.emoji)
                .font(.title3)
            Text("\(amount)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isChanged ? (amount > previousAmount ? .green : .red) : .primary)
                .animation(.easeInOut(duration: 0.3), value: isChanged)
            Text(resource.name)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .scaleEffect(isChanged ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isChanged)
        .onChange(of: amount) { newAmount in
            if previousAmount != 0 && newAmount != previousAmount {
                withAnimation {
                    isChanged = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        isChanged = false
                    }
                }
            }
            previousAmount = newAmount
        }
        .onAppear {
            previousAmount = amount
        }
    }
}

struct TutorialOverlay: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("🎮 How to Play")
                    .font(.title)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 12) {
                    TutorialStep(icon: "🏘️", text: "Click your green village to build and recruit")
                    TutorialStep(icon: "🏗️", text: "Build Farms for food, Barracks for units")
                    TutorialStep(icon: "⚔️", text: "Recruit units to defend and attack")
                    TutorialStep(icon: "🚶", text: "Tap your units to select, then tap a green tile to move")
                    TutorialStep(icon: "💥", text: "Move next to enemy villages (red) and tap them to attack")
                    TutorialStep(icon: "🎯", text: "Goal: Conquer all enemy villages to win!")
                    TutorialStep(icon: "⏭️", text: "Press 'Next Turn' when ready")
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPresented = false
                    }
                }) {
                    Text("Got it!")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.green)
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

struct TutorialStep: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(.title2)
            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct BuildingCardSimple: View {
    let building: Building
    let village: Village
    let onUpgrade: (UUID) -> Void

    var body: some View {
        let upgradeCheck = BuildingConstructionEngine().canUpgradeBuilding(building, in: village)
        let globalResources = GameManager.shared.getGlobalResources(playerID: village.owner)

        HStack(spacing: 8) {
            Text(buildingIcon).font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(building.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                HStack(spacing: 4) {
                    Text("L\(building.level)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    if !building.resourcesProduction.isEmpty {
                        ForEach(Array(building.resourcesProduction.keys), id: \.self) { resource in
                            if let amount = building.resourcesProduction[resource] {
                                Text("\(resource.emoji)+\(amount)")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }

            Spacer()

            if upgradeCheck.can {
                Button(action: { onUpgrade(building.id) }) {
                    VStack(spacing: 1) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title3)
                            .foregroundColor(.green)
                        HStack(spacing: 2) {
                            ForEach(Array(upgradeCheck.cost.keys.prefix(2)), id: \.self) { resource in
                                if let cost = upgradeCheck.cost[resource] {
                                    let has = globalResources[resource] ?? 0
                                    Text("\(resource.emoji)\(cost)")
                                        .font(.system(size: 8))
                                        .foregroundColor(has >= cost ? .secondary : .red)
                                }
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }

    var buildingIcon: String {
        switch building.name {
        case "Farm": return "🌾"
        case "Lumber Mill": return "🪵"
        case "Mine": return "⛏️"
        case "Barracks": return "⚔️"
        case "Archery Range": return "🏹"
        case "Walls": return "🏰"
        case "Market": return "🏪"
        case "Tavern": return "🍺"
        case "Town Hall": return "🏛️"
        default: return "🏠"
        }
    }
}
