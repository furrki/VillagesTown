//
//  MobileGameLayout.swift
//  VillagesTown
//
//  Mobile layout: Streamlined for minimal interactions
//

import SwiftUI

struct MobileGameLayout: View {
    @ObservedObject var gameManager = GameManager.shared
    @State private var selectedVillage: Village?
    @State private var selectedArmy: Army?
    @State private var isProcessingTurn = false
    @State private var toastMessage: String?

    // Map gesture states
    @State private var mapScale: CGFloat = 1.0
    @State private var mapOffset: CGSize = .zero
    @GestureState private var magnifyBy: CGFloat = 1.0
    @GestureState private var dragOffset: CGSize = .zero

    // Send army state
    @State private var showSendArmySheet = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(spacing: 0) {
                    // MAP (50%)
                    mapSection(height: geo.size.height * 0.50)

                    // ACTION PANEL (50%)
                    actionPanel(height: geo.size.height * 0.50)
                }

                // Toast overlay
                if let message = toastMessage {
                    VStack {
                        Spacer()
                        Text(message)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.85))
                            .cornerRadius(20)
                            .padding(.bottom, geo.size.height * 0.46)
                    }
                    .transition(.opacity)
                    .zIndex(100)
                }
            }
        }
        .background(Color.black)
        .sheet(isPresented: $showSendArmySheet) {
            if let village = currentVillage,
               let army = gameManager.getArmiesAt(villageID: village.id).first(where: { $0.owner == "player" }) {
                MobileSendArmySheet(army: army, currentVillage: village) { destination in
                    _ = gameManager.sendArmy(armyID: army.id, to: destination.id)
                    showSendArmySheet = false
                    showToast("Army marching to \(destination.name)")
                }
                .presentationDetents([.medium])
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if !gameManager.gameStarted {
                gameManager.initializeGame()
            }
            selectedVillage = gameManager.getPlayerVillages(playerID: "player").first
        }
    }

    var currentVillage: Village? {
        guard let sv = selectedVillage else { return nil }
        return gameManager.map.villages.first { $0.id == sv.id }
    }

    // MARK: - Map Section

    func mapSection(height: CGFloat) -> some View {
        ZStack {
            Color(red: 0.15, green: 0.2, blue: 0.15)

            GeometryReader { geo in
                ZStack {
                    // Connections
                    ForEach(gameManager.map.villages, id: \.id) { village in
                        ForEach(getConnectedVillages(for: village), id: \.id) { other in
                            Path { path in
                                path.move(to: villagePosition(village, in: geo.size))
                                path.addLine(to: villagePosition(other, in: geo.size))
                            }
                            .stroke(Color.white.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        }
                    }

                    // Marching armies
                    ForEach(gameManager.armies.filter { $0.isMarching }, id: \.id) { army in
                        if let origin = gameManager.map.villages.first(where: { $0.id == army.origin }),
                           let dest = gameManager.map.villages.first(where: { $0.id == army.destination }) {
                            let progress = calculateMarchProgress(army: army, from: origin, to: dest)
                            let fromPos = villagePosition(origin, in: geo.size)
                            let toPos = villagePosition(dest, in: geo.size)
                            let pos = CGPoint(
                                x: fromPos.x + (toPos.x - fromPos.x) * progress,
                                y: fromPos.y + (toPos.y - fromPos.y) * progress
                            )
                            MarchingArmyMarker(army: army, isSelected: selectedArmy?.id == army.id)
                                .position(pos)
                                .onTapGesture { selectArmy(army) }
                        }
                    }

                    // Villages
                    ForEach(gameManager.map.villages, id: \.id) { village in
                        let pos = villagePosition(village, in: geo.size)
                        let armies = gameManager.getArmiesAt(villageID: village.id)
                        let armyStrength = armies.reduce(0) { $0 + $1.strength }

                        VillageMarker(
                            village: village,
                            isSelected: selectedVillage?.id == village.id,
                            armyStrength: armyStrength,
                            hasThreat: hasIncomingThreat(to: village)
                        )
                        .position(pos)
                        .onTapGesture { selectVillage(village) }
                    }
                }
                .scaleEffect(mapScale * magnifyBy)
                .offset(x: mapOffset.width + dragOffset.width, y: mapOffset.height + dragOffset.height)
            }
            .gesture(mapGestures)
            .clipped()

            // Compact top HUD
            VStack {
                compactHUD
                Spacer()
            }
        }
        .frame(height: height)
    }

    // MARK: - Compact HUD (single row)

    var compactHUD: some View {
        HStack(spacing: 8) {
            // Turn badge
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
                    .frame(width: 32, height: 32)
                Text("\(gameManager.currentTurn)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            // Resources - compact
            HStack(spacing: 8) {
                ForEach([Resource.gold, Resource.food, Resource.iron, Resource.wood], id: \.self) { resource in
                    let amount = gameManager.getGlobalResources(playerID: "player")[resource] ?? 0
                    HStack(spacing: 2) {
                        Text(resource.emoji).font(.system(size: 12))
                        Text("\(amount)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(amount < 20 ? .orange : .white)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.7))
            .cornerRadius(8)

            Spacer()

            // Victory
            let pCount = gameManager.getPlayerVillages(playerID: "player").count
            let tCount = gameManager.map.villages.count
            HStack(spacing: 4) {
                Image(systemName: "crown.fill").font(.system(size: 10)).foregroundColor(.yellow)
                Text("\(pCount)/\(tCount)").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.7))
            .cornerRadius(8)
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
    }

    // MARK: - Action Panel (45%)

    func actionPanel(height: CGFloat) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1)

            if let village = currentVillage {
                InlineVillagePanel(
                    village: village,
                    onBuild: { building in quickBuild(building, in: village) },
                    onUpgrade: { building in quickUpgrade(building, in: village) },
                    onRecruit: { type in quickRecruit(type, in: village) },
                    onSendArmy: { showSendArmySheet = true },
                    onEndTurn: processTurn,
                    isProcessingTurn: isProcessingTurn,
                    showToast: showToast
                )
            } else if let army = selectedArmy {
                ArmyActionPanel(army: army, onEndTurn: processTurn, isProcessingTurn: isProcessingTurn)
            } else {
                EmptySelectionPanel(onEndTurn: processTurn, isProcessingTurn: isProcessingTurn)
            }
        }
        .frame(height: height)
        .background(Color(white: 0.08))
    }

    // MARK: - Helpers

    var mapGestures: some Gesture {
        let drag = DragGesture()
            .updating($dragOffset) { v, s, _ in s = v.translation }
            .onEnded { v in
                mapOffset.width += v.translation.width
                mapOffset.height += v.translation.height
            }
        let magnify = MagnificationGesture()
            .updating($magnifyBy) { v, s, _ in s = v }
            .onEnded { v in mapScale = min(max(mapScale * v, 0.5), 3.0) }
        return drag.simultaneously(with: magnify)
    }

    func selectVillage(_ village: Village) {
        LayoutConstants.selectionFeedback()
        withAnimation(.easeOut(duration: 0.15)) {
            selectedVillage = village
            selectedArmy = nil
        }
    }

    func selectArmy(_ army: Army) {
        LayoutConstants.selectionFeedback()
        withAnimation(.easeOut(duration: 0.15)) {
            selectedArmy = army
            selectedVillage = nil
        }
    }

    func villagePosition(_ village: Village, in size: CGSize) -> CGPoint {
        let mapW = CGFloat(gameManager.map.size.width)
        let mapH = CGFloat(gameManager.map.size.height)
        let padX = size.width * 0.08
        let padY = size.height * 0.08
        return CGPoint(
            x: padX + (village.coordinates.x / mapW) * (size.width - padX * 2),
            y: padY + (village.coordinates.y / mapH) * (size.height - padY * 2)
        )
    }

    func getConnectedVillages(for village: Village) -> [Village] {
        gameManager.map.villages.filter { o in
            guard o.id != village.id else { return false }
            let dx = o.coordinates.x - village.coordinates.x
            let dy = o.coordinates.y - village.coordinates.y
            return sqrt(dx*dx + dy*dy) < 8
        }
    }

    func hasIncomingThreat(to village: Village) -> Bool {
        gameManager.armies.contains { $0.isMarching && $0.destination == village.id && $0.owner != village.owner }
    }

    func calculateMarchProgress(army: Army, from: Village, to: Village) -> CGFloat {
        let total = Army.calculateTravelTime(from: from.coordinates, to: to.coordinates)
        let remaining = army.turnsUntilArrival
        return CGFloat(total - remaining) / CGFloat(max(total, 1))
    }

    // MARK: - Actions

    func processTurn() {
        isProcessingTurn = true
        LayoutConstants.impactFeedback(style: .medium)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            gameManager.turnEngine.doTurn()
            if let sv = selectedVillage {
                selectedVillage = gameManager.map.villages.first { $0.id == sv.id }
            }
            isProcessingTurn = false
        }
    }

    func quickBuild(_ building: Building, in village: Village) {
        var v = village
        if BuildingConstructionEngine().buildBuilding(building: building, in: &v) {
            gameManager.updateVillage(v)
            selectedVillage = gameManager.map.villages.first { $0.id == v.id }
            showToast("Built \(building.name)")
        } else {
            showToast("Can't build - check resources")
        }
    }

    func quickUpgrade(_ building: Building, in village: Village) {
        var v = village
        if BuildingConstructionEngine().upgradeBuilding(buildingID: building.id, in: &v) {
            gameManager.updateVillage(v)
            selectedVillage = gameManager.map.villages.first { $0.id == v.id }
            showToast("\(building.name) upgraded to Lv.\(building.level + 1)")
        } else {
            showToast("Can't upgrade - check resources")
        }
    }

    func quickRecruit(_ type: Unit.UnitType, in village: Village) {
        var v = village
        let units = RecruitmentEngine().recruitUnits(unitType: type, quantity: 1, in: &v, at: v.coordinates)
        if !units.isEmpty {
            gameManager.updateVillage(v)
            selectedVillage = gameManager.map.villages.first { $0.id == v.id }
            showToast("Recruited \(type.rawValue)")
        } else {
            showToast("Can't recruit - check requirements")
        }
    }

    func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { toastMessage = nil }
        }
    }
}

// MARK: - Inline Village Panel (No sheets needed!)

struct InlineVillagePanel: View {
    let village: Village
    let onBuild: (Building) -> Void
    let onUpgrade: (Building) -> Void
    let onRecruit: (Unit.UnitType) -> Void
    let onSendArmy: () -> Void
    let onEndTurn: () -> Void
    let isProcessingTurn: Bool
    let showToast: (String) -> Void

    @ObservedObject var gameManager = GameManager.shared

    var isPlayerVillage: Bool { village.owner == "player" }
    var resources: [Resource: Int] { gameManager.getGlobalResources(playerID: "player") }
    var playerArmy: Army? {
        gameManager.getArmiesAt(villageID: village.id).first { $0.owner == "player" }
    }

    var availableBuildings: [Building] {
        Building.all.filter { b in !village.buildings.contains { $0.name == b.name } }
    }

    // Available unit types based on buildings
    var availableUnits: [Unit.UnitType] {
        var units: [Unit.UnitType] = []
        let hasBarracks = village.buildings.contains { $0.name == "Barracks" }
        let hasArchery = village.buildings.contains { $0.name == "Archery Range" }
        let hasStables = village.buildings.contains { $0.name == "Stables" }
        if hasBarracks { units.append(contentsOf: [.militia, .spearman, .swordsman]) }
        if hasArchery { units.append(contentsOf: [.archer, .crossbowman]) }
        if hasStables { units.append(contentsOf: [.lightCavalry, .knight]) }
        return units
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header + End Turn
                villageHeader

                if isPlayerVillage {
                    // Stats row
                    statsRow

                    // Army section (if exists)
                    if let army = playerArmy {
                        armySection(army)
                    }

                    // Quick Build section
                    if village.buildings.count < village.maxBuildings {
                        quickBuildSection
                    }

                    // Existing buildings with upgrade
                    if !village.buildings.isEmpty {
                        existingBuildingsSection
                    }

                    // Quick Recruit section
                    if !availableUnits.isEmpty {
                        quickRecruitSection
                    } else {
                        noMilitaryBuildingsHint
                    }
                } else {
                    enemyVillageSection
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }

    var villageHeader: some View {
        HStack(spacing: 12) {
            OwnerFlagView(owner: village.owner, size: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(village.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text(isPlayerVillage ? "Level \(village.level.rawValue)" : ownerLabel)
                    .font(.system(size: 13))
                    .foregroundColor(isPlayerVillage ? .green : .red)
            }
            Spacer()
            endTurnButton
        }
    }

    var ownerLabel: String {
        switch village.owner {
        case "neutral": return "Neutral"
        case "ai1", "ai2": return "Enemy"
        default: return village.owner
        }
    }

    var endTurnButton: some View {
        Button(action: onEndTurn) {
            HStack(spacing: 6) {
                if isProcessingTurn {
                    ProgressView().scaleEffect(0.8).tint(.white)
                } else {
                    Image(systemName: "arrow.right.circle.fill").font(.system(size: 16))
                }
                Text("End Turn").font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Capsule().fill(Color.blue))
            .shadow(color: .blue.opacity(0.4), radius: 4, y: 2)
        }
        .disabled(isProcessingTurn)
    }

    var statsRow: some View {
        HStack(spacing: 0) {
            statCell(icon: "person.3.fill", value: "\(village.population)", label: "Population", color: .blue)
            Divider().frame(height: 44).background(Color.white.opacity(0.1))
            statCell(icon: "shield.fill", value: "\(village.garrisonStrength)", label: "Defense", color: .green)
            Divider().frame(height: 44).background(Color.white.opacity(0.1))
            statCell(icon: "building.2.fill", value: "\(village.buildings.count)/\(village.maxBuildings)", label: "Buildings", color: .orange)
        }
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    func statCell(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
                Text(value).font(.system(size: 17, weight: .bold)).foregroundColor(.white)
            }
            Text(label).font(.system(size: 10)).foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    func armySection(_ army: Army) -> some View {
        HStack(spacing: 12) {
            Text(army.emoji).font(.system(size: 32))
            VStack(alignment: .leading, spacing: 3) {
                Text(army.name).font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                Text("\(army.unitCount) units • \(army.strength) STR")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            Button(action: onSendArmy) {
                HStack(spacing: 5) {
                    Image(systemName: "paperplane.fill").font(.system(size: 14))
                    Text("Send").font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.orange))
                .shadow(color: .orange.opacity(0.4), radius: 4, y: 2)
            }
        }
        .padding(14)
        .background(Color.blue.opacity(0.15))
        .cornerRadius(14)
    }

    var quickBuildSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("BUILD NEW")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(availableBuildings.prefix(8), id: \.id) { building in
                        InlineBuildButton(building: building, resources: resources, onBuild: { onBuild(building) })
                    }
                }
            }
        }
    }

    var existingBuildingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("UPGRADE")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(village.buildings, id: \.id) { building in
                        InlineUpgradeButton(building: building, resources: resources, onUpgrade: { onUpgrade(building) })
                    }
                }
            }
        }
    }

    var quickRecruitSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RECRUIT UNITS")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(availableUnits, id: \.self) { type in
                        InlineRecruitButton(type: type, resources: resources, onRecruit: { onRecruit(type) })
                    }
                }
            }
        }
    }

    var noMilitaryBuildingsHint: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(.orange)
            Text("Build Barracks, Archery Range, or Stables to recruit units")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(14)
        .background(Color.orange.opacity(0.12))
        .cornerRadius(12)
    }

    var enemyVillageSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.red)
                Text("Garrison Strength: \(village.garrisonStrength)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            Text("Send an army to conquer this village")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(20)
        .background(Color.red.opacity(0.1))
        .cornerRadius(14)
    }
}

// MARK: - Quick Action Buttons

struct InlineBuildButton: View {
    let building: Building
    let resources: [Resource: Int]
    let onBuild: () -> Void

    var canAfford: Bool {
        for (res, cost) in building.baseCost {
            if (resources[res] ?? 0) < cost { return false }
        }
        return true
    }

    var icon: String {
        switch building.name {
        case "Farm": return "🌾"
        case "Lumber Mill": return "🪵"
        case "Iron Mine": return "⛏️"
        case "Market": return "🏪"
        case "Barracks": return "⚔️"
        case "Archery Range": return "🏹"
        case "Stables": return "🐴"
        case "Fortress": return "🏰"
        case "Granary": return "🏛️"
        default: return "🏠"
        }
    }

    var body: some View {
        Button(action: {
            LayoutConstants.impactFeedback()
            onBuild()
        }) {
            VStack(spacing: 6) {
                Text(icon).font(.system(size: 28))
                Text(building.name.prefix(8) + (building.name.count > 8 ? ".." : ""))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                HStack(spacing: 3) {
                    Text("💰").font(.system(size: 10))
                    Text("\(building.baseCost[.gold] ?? 0)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(canAfford ? .yellow : .red)
                }
            }
            .frame(width: 76, height: 82)
            .background(Color.white.opacity(canAfford ? 0.1 : 0.04))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(canAfford ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
        .disabled(!canAfford)
        .opacity(canAfford ? 1 : 0.5)
    }
}

struct InlineUpgradeButton: View {
    let building: Building
    let resources: [Resource: Int]
    let onUpgrade: () -> Void

    var upgradeCost: [Resource: Int] {
        BuildingConstructionEngine().getUpgradeCost(for: building)
    }

    var canUpgrade: Bool {
        guard building.level < 5 else { return false }
        for (res, cost) in upgradeCost {
            if (resources[res] ?? 0) < cost { return false }
        }
        return true
    }

    var icon: String {
        switch building.name {
        case "Farm": return "🌾"
        case "Lumber Mill": return "🪵"
        case "Iron Mine": return "⛏️"
        case "Market": return "🏪"
        case "Barracks": return "⚔️"
        case "Archery Range": return "🏹"
        case "Stables": return "🐴"
        case "Fortress": return "🏰"
        default: return "🏠"
        }
    }

    var body: some View {
        Button(action: {
            LayoutConstants.impactFeedback()
            onUpgrade()
        }) {
            VStack(spacing: 5) {
                ZStack(alignment: .topTrailing) {
                    Text(icon).font(.system(size: 26))
                    Text("\(building.level)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                        .padding(4)
                        .background(Circle().fill(Color.yellow))
                        .offset(x: 8, y: -6)
                }
                Text(building.name.prefix(8) + (building.name.count > 8 ? ".." : ""))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                if building.level < 5 {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 12))
                        Text("Lv.\(building.level + 1)")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(canUpgrade ? .green : .gray)
                } else {
                    Text("MAX")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            .frame(width: 76, height: 82)
            .background(Color.white.opacity(canUpgrade ? 0.1 : 0.04))
            .cornerRadius(12)
        }
        .disabled(!canUpgrade)
        .opacity(canUpgrade || building.level >= 5 ? 1 : 0.5)
    }
}

struct InlineRecruitButton: View {
    let type: Unit.UnitType
    let resources: [Resource: Int]
    let onRecruit: () -> Void

    var stats: (name: String, attack: Int, defense: Int, hp: Int, movement: Int, cost: [Resource: Int], upkeep: [Resource: Int]) {
        Unit.getStats(for: type)
    }

    var canAfford: Bool {
        for (res, cost) in stats.cost {
            if (resources[res] ?? 0) < cost { return false }
        }
        return true
    }

    var body: some View {
        Button(action: {
            LayoutConstants.impactFeedback()
            onRecruit()
        }) {
            VStack(spacing: 5) {
                Text(type.emoji).font(.system(size: 28))
                Text(type.rawValue.prefix(8) + (type.rawValue.count > 8 ? ".." : ""))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                HStack(spacing: 3) {
                    Text("💰").font(.system(size: 10))
                    Text("\(stats.cost[.gold] ?? 0)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(canAfford ? .yellow : .red)
                }
            }
            .frame(width: 76, height: 82)
            .background(Color.white.opacity(canAfford ? 0.1 : 0.04))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(canAfford ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
        .disabled(!canAfford)
        .opacity(canAfford ? 1 : 0.5)
    }
}

// MARK: - Flag View (shows OWNER's flag, not village nationality)

struct OwnerFlagView: View {
    let owner: String
    let size: CGFloat

    var ownerNationality: Nationality? {
        GameManager.shared.players.first { $0.id == owner }?.nationality
    }

    var flagColor: Color {
        switch owner {
        case "player": return .blue
        case "ai1": return .cyan
        case "ai2": return .purple
        case "neutral": return .gray
        default: return .gray
        }
    }

    var flag: String {
        ownerNationality?.flag ?? "🏳️"
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(flagColor.opacity(0.3))
                .frame(width: size, height: size)
            Text(flag)
                .font(.system(size: size * 0.7))
                .minimumScaleFactor(0.5)
        }
    }
}

// MARK: - Village Marker

struct VillageMarker: View {
    let village: Village
    let isSelected: Bool
    let armyStrength: Int
    let hasThreat: Bool

    var ownerColor: Color {
        switch village.owner {
        case "player": return .blue
        case "ai1": return .red
        case "ai2": return .orange
        default: return .gray
        }
    }

    var body: some View {
        ZStack {
            // Selection ring
            if isSelected {
                Circle()
                    .stroke(ownerColor, lineWidth: 3)
                    .frame(width: 70, height: 70)
            }

            // Threat pulse
            if hasThreat {
                Circle()
                    .stroke(Color.red, lineWidth: 2)
                    .frame(width: 75, height: 75)
                    .opacity(0.6)
            }

            // Main circle
            VStack(spacing: 2) {
                OwnerFlagView(owner: village.owner, size: 28)
                Text(village.name)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(width: 60, height: 60)
            .background(
                Circle()
                    .fill(isSelected ? ownerColor : Color.black.opacity(0.8))
                    .overlay(Circle().stroke(ownerColor, lineWidth: 2))
            )

            // Army badge
            if armyStrength > 0 {
                Text("\(armyStrength)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.blue))
                    .offset(x: 25, y: -25)
            }
        }
    }
}

// MARK: - Marching Army Marker

struct MarchingArmyMarker: View {
    let army: Army
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(army.emoji)
                .font(.system(size: 20))
            Text("\(army.turnsUntilArrival)t")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(6)
        .background(
            Circle()
                .fill(army.owner == "player" ? Color.blue.opacity(0.9) : Color.red.opacity(0.9))
                .overlay(Circle().stroke(isSelected ? Color.white : Color.clear, lineWidth: 2))
        )
    }
}

// MARK: - Village Action Panel

struct VillageActionPanel: View {
    let village: Village
    let onBuild: () -> Void
    let onRecruit: () -> Void
    let onSendArmy: () -> Void
    let onEndTurn: () -> Void
    let isProcessingTurn: Bool

    @ObservedObject var gameManager = GameManager.shared

    var isPlayerVillage: Bool { village.owner == "player" }
    var armies: [Army] { gameManager.getArmiesAt(villageID: village.id) }
    var playerArmy: Army? { armies.first { $0.owner == "player" } }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(village.nationality.flag)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(village.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(isPlayerVillage ? "Your Village" : "Enemy Village")
                        .font(.caption)
                        .foregroundColor(isPlayerVillage ? .green : .red)
                }
                Spacer()
                endTurnButton
            }
            .padding()
            .background(Color.white.opacity(0.05))

            if isPlayerVillage {
                // Stats row
                HStack(spacing: 0) {
                    statItem(icon: "person.3.fill", value: "\(village.population)", label: "Pop")
                    Divider().frame(height: 40)
                    statItem(icon: "shield.fill", value: "\(village.garrisonStrength)", label: "Garrison")
                    Divider().frame(height: 40)
                    statItem(icon: "building.2.fill", value: "\(village.buildings.count)/\(village.maxBuildings)", label: "Buildings")
                }
                .padding(.vertical, 8)

                Divider()

                // Action buttons
                HStack(spacing: 12) {
                    actionButton(icon: "hammer.fill", label: "Build", color: .orange) {
                        onBuild()
                    }
                    actionButton(icon: "person.3.fill", label: "Recruit", color: .green) {
                        onRecruit()
                    }
                    actionButton(icon: "paperplane.fill", label: "Send Army", color: .blue, disabled: playerArmy == nil) {
                        onSendArmy()
                    }
                }
                .padding()
            } else {
                // Enemy info
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "shield.fill")
                            .foregroundColor(.red)
                        Text("Garrison: \(village.garrisonStrength)")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    Text("Send an army to conquer this village")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding()

                Spacer()
            }
        }
    }

    func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.6))
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    func actionButton(icon: String, label: String, color: Color, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: {
            LayoutConstants.impactFeedback()
            action()
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(disabled ? .gray : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(disabled ? Color.gray.opacity(0.2) : color.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(disabled ? Color.gray.opacity(0.3) : color, lineWidth: 1)
                    )
            )
        }
        .disabled(disabled)
    }

    var endTurnButton: some View {
        Button(action: {
            LayoutConstants.impactFeedback(style: .medium)
            onEndTurn()
        }) {
            HStack(spacing: 4) {
                if isProcessingTurn {
                    ProgressView().scaleEffect(0.7).tint(.white)
                } else {
                    Image(systemName: "arrow.right")
                }
                Text("End Turn")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.blue))
        }
        .disabled(isProcessingTurn)
    }
}

// MARK: - Army Action Panel

struct ArmyActionPanel: View {
    let army: Army
    let onEndTurn: () -> Void
    let isProcessingTurn: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(army.emoji)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(army.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(army.isMarching ? "Marching • \(army.turnsUntilArrival) turns" : "\(army.unitCount) units")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()

                Button(action: {
                    LayoutConstants.impactFeedback(style: .medium)
                    onEndTurn()
                }) {
                    HStack(spacing: 4) {
                        if isProcessingTurn {
                            ProgressView().scaleEffect(0.7).tint(.white)
                        } else {
                            Image(systemName: "arrow.right")
                        }
                        Text("End Turn")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.blue))
                }
                .disabled(isProcessingTurn)
            }
            .padding()
            .background(Color.white.opacity(0.05))

            // Army stats
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(army.unitCount)")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Units")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 50)

                VStack(spacing: 4) {
                    Image(systemName: "burst.fill")
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(army.strength)")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Strength")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
            }
            .padding()

            Spacer()
        }
    }
}

// MARK: - Empty Selection Panel

struct EmptySelectionPanel: View {
    let onEndTurn: () -> Void
    let isProcessingTurn: Bool

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "hand.tap")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.3))

            Text("Select a village on the map")
                .font(.headline)
                .foregroundColor(.white.opacity(0.5))

            Spacer()

            Button(action: {
                LayoutConstants.impactFeedback(style: .medium)
                onEndTurn()
            }) {
                HStack(spacing: 6) {
                    if isProcessingTurn {
                        ProgressView().scaleEffect(0.8).tint(.white)
                    } else {
                        Image(systemName: "arrow.right")
                    }
                    Text("End Turn")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Capsule().fill(Color.blue))
            }
            .disabled(isProcessingTurn)
            .padding(.bottom, 20)
        }
    }
}

