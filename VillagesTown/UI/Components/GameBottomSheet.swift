//
//  GameBottomSheet.swift
//  VillagesTown
//
//  Bottom sheet for mobile game with village details and actions
//

import SwiftUI

struct GameBottomSheet: View {
    @Binding var selectedVillage: Village?
    @Binding var selectedArmy: Army?
    @Binding var isProcessingTurn: Bool
    let onEndTurn: () -> Void

    @ObservedObject var gameManager = GameManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Drag Handle
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 4)

            // Collapsed header (always visible)
            collapsedHeader
                .padding(.horizontal)
                .padding(.top, 4)

            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.vertical, 12)

            // Expandable content
            ScrollView {
                VStack(spacing: 20) {
                    if let village = selectedVillage {
                        MobileVillagePanel(
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
                        MobileArmyPanel(army: army)
                    } else {
                        MobileEmpireOverview()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .background(MaterialEffectView(material: .systemThickMaterialDark))
    }

    // MARK: - Collapsed Header

    var collapsedHeader: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(headerColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: headerIcon)
                    .font(.system(size: 20))
                    .foregroundColor(headerColor)
            }

            // Title & Subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(headerTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text(headerSubtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            // End Turn Button
            Button(action: onEndTurn) {
                HStack(spacing: 6) {
                    if isProcessingTurn {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    Text("End Turn")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isProcessingTurn ? Color.orange : Color.blue)
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(isProcessingTurn)
        }
    }
    
    // Header properties
    var headerColor: Color {
        if selectedVillage != nil { return .green }
        if selectedArmy != nil { return .blue }
        return .purple
    }
    
    var headerIcon: String {
        if selectedVillage != nil { return "building.2.fill" }
        if selectedArmy != nil { return "figure.stand" }
        return "map.fill"
    }
    
    var headerTitle: String {
        if let village = selectedVillage { return village.name }
        if let army = selectedArmy { return army.name }
        return "Empire Overview"
    }
    
    var headerSubtitle: String {
        if let village = selectedVillage { return "\(village.nationality.name) • Level \(village.level.rawValue)" }
        if let army = selectedArmy { return army.isMarching ? "Marching..." : "Stationary" }
        return "Tap on map to select items"
    }
}

// MARK: - Mobile Village Panel

struct MobileVillagePanel: View {
    let village: Village
    let onSendArmy: (Army, Village) -> Void
    let onUpdate: () -> Void

    @State private var showSendArmy = false
    @State private var showMessage = ""
    @State private var showingMessage = false

    let buildingEngine = BuildingConstructionEngine()
    let recruitmentEngine = RecruitmentEngine()
    
    var isPlayerVillage: Bool { village.owner == "player" }
    
    var armies: [Army] {
        GameManager.shared.getArmiesAt(villageID: village.id).filter { $0.owner == "player" }
    }

    var body: some View {
        VStack(spacing: 24) {
            if isPlayerVillage {
                // Stats Grid
                statsGrid
                
                // Units & Recruitment
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Military")
                    
                    if !armies.isEmpty {
                        MobileArmyCard(army: armies[0]) {
                            showSendArmy = true
                        }
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            recruitButton(emoji: "🗡️", cost: 10, type: .militia)
                            recruitButton(emoji: "⚔️", cost: 30, type: .swordsman)
                            recruitButton(emoji: "🏹", cost: 40, type: .archer)
                            recruitButton(emoji: "🐴", cost: 80, type: .lightCavalry)
                        }
                    }
                }
                
                // Buildings
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Construction")
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        buildButton(icon: "🌾", name: "Farm", building: .farm)
                        buildButton(icon: "⛏️", name: "Mine", building: .ironMine)
                        buildButton(icon: "🪵", name: "Lumber", building: .lumberMill)
                        buildButton(icon: "⚔️", name: "Barracks", building: .barracks)
                    }
                }

            } else {
                Text("Enemy Village details hidden")
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showSendArmy) {
            if let army = armies.first {
                MobileSendArmySheet(
                    army: army,
                    currentVillage: village,
                    onSend: { destination in
                        onSendArmy(army, destination)
                        showSendArmy = false
                    }
                )
                .presentationDetents([.medium, .large])
            }
        }
        .overlay(toastOverlay, alignment: .top)
    }
    
    var statsGrid: some View {
        HStack(spacing: 12) {
            MobileStatCard(icon: "person.3.fill", value: "\(village.population)", label: "Citizens", color: .blue)
            MobileStatCard(icon: "shield.fill", value: "\(village.garrisonStrength)", label: "Defense", color: .green)
            MobileStatCard(icon: "building.2.fill", value: "\(village.buildings.count)/\(village.maxBuildings)", label: "Buildings", color: .orange)
        }
    }
    
    func recruitButton(emoji: String, cost: Int, type: Unit.UnitType) -> some View {
        Button(action: { quickRecruit(type, quantity: 1) }) {
            VStack(spacing: 8) {
                Text(emoji).font(.title)
                Text("\(cost)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
            }
            .frame(width: 70, height: 80)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    func buildButton(icon: String, name: String, building: Building) -> some View {
        Button(action: { quickBuild(building) }) {
            HStack {
                Text(icon).font(.title2)
                VStack(alignment: .leading) {
                    Text(name).font(.caption).fontWeight(.bold)
                    Text("\(building.baseCost[.gold] ?? 0)").font(.caption2).foregroundColor(.yellow)
                }
                Spacer()
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // Helper functions (same logic as before)
    func quickBuild(_ building: Building) {
        LayoutConstants.impactFeedback()
        var mutableVillage = village
        if buildingEngine.buildBuilding(building: building, in: &mutableVillage) {
            GameManager.shared.updateVillage(mutableVillage)
            showToast("Built \(building.name)!")
            onUpdate()
        } else {
             showToast("Cannot build \(building.name)")
        }
    }

    func quickRecruit(_ unitType: Unit.UnitType, quantity: Int) {
         LayoutConstants.impactFeedback()
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
         } else {
             showToast("Not enough resources")
         }
    }
    
    func showToast(_ message: String) {
        showMessage = message
        withAnimation { showingMessage = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
             withAnimation { showingMessage = false }
        }
    }
    
    var toastOverlay: some View {
        Group {
            if showingMessage {
                Text(showMessage)
                    .font(.caption)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, -20)
            }
        }
    }
}

// MARK: - Components

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.caption)
            .fontWeight(.bold)
            .tracking(1)
            .foregroundColor(.white.opacity(0.4))
    }
}

struct MobileStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct MobileArmyCard: View {
    let army: Army
    let onAction: () -> Void
    
    var body: some View {
        HStack {
            ZStack {
                Circle().fill(Color.blue.opacity(0.2)).frame(width: 48, height: 48)
                Text(army.emoji).font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(army.name).font(.headline).fontWeight(.bold)
                Text("\(army.unitCount) Soldiers • \(army.strength) STR")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Button(action: onAction) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Circle().fill(Color.blue))
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Mobile Empire Overview (Placeholder refactor)
struct MobileEmpireOverview: View {
    var body: some View {
        VStack(spacing: 16) {
           Text("Select a village to manage")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 20)
        }
    }
}

// MARK: - Mobile Army Panel (Placeholder refactor)
struct MobileArmyPanel: View {
    let army: Army
    var body: some View {
        MobileArmyCard(army: army, onAction: {})
    }
}

// Send sheet needs to be retained
struct MobileSendArmySheet: View {
    let army: Army
    let currentVillage: Village
    let onSend: (Village) -> Void
    @Environment(\.dismiss) var dismiss

    var destinations: [Village] {
        GameManager.shared.map.villages.filter { $0.id != currentVillage.id }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(destinations, id: \.id) { village in
                    Button(action: { onSend(village) }) {
                        HStack {
                            Text(village.nationality.flag)
                                .font(.title2)

                            VStack(alignment: .leading) {
                                Text(village.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                HStack(spacing: 8) {
                                    Text(village.owner == "player" ? "Your village" : ownerLabel(village.owner))
                                        .font(.caption)
                                        .foregroundColor(village.owner == "player" ? .green : .red)

                                    Text("🛡️ \(village.garrisonStrength)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            let turns = Army.calculateTravelTime(from: currentVillage.coordinates, to: village.coordinates)
                            Text("\(turns) turns")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Send Army")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    func ownerLabel(_ owner: String) -> String {
        switch owner {
        case "neutral": return "Neutral"
        case "ai1": return "Enemy AI-1"
        case "ai2": return "Enemy AI-2"
        default: return owner
        }
    }
}
