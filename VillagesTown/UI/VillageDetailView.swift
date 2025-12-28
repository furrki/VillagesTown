//
//  VillageDetailView.swift
//  VillagesTown
//
//  Created by Claude Code
//

import SwiftUI

struct VillageDetailView: View {
    let village: Village
    @Binding var isPresented: Bool
    let onUpdate: () -> Void
    @State private var showBuildSection = true
    @State private var showRecruitSection = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(village.name)
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button("Close") {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }
            }
            .padding()
            .background(Color(white: 0.1))

            Divider()

            // Content
            overviewContent
        }
    }

    var overviewContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                // Compact header with stats inline
                HStack(spacing: 6) {
                    Text(village.nationality.flag).font(.title3)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(village.name).font(.subheadline).fontWeight(.bold)
                        Text(village.level.displayName).font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                    // Stats inline
                    HStack(spacing: 6) {
                        CompactStat(icon: "person.3.fill", value: "\(village.population)/\(village.populationCapacity)")
                        CompactStat(icon: happinessIcon, value: "\(village.totalHappiness)%")
                        CompactStat(icon: "shield.fill", value: "+\(Int(village.defenseBonus * 100))%")
                        CompactStat(icon: "chart.line.uptrend.xyaxis", value: "+\(Int(village.productionBonus * 100))%")
                    }
                }
                .padding(6)
                .background(Color(.systemGray).opacity(0.2))
                .cornerRadius(4)

                // Resources in compact row
                resourcesSection

                Divider()

                // Stationed Units
                stationedUnitsSection

                Divider()

                // Buildings
                buildingsSection

                Divider()

                // Build (Collapsible)
                buildSection

                Divider()

                // Recruit (Collapsible)
                recruitSection

                Spacer()
            }
            .padding(6)
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
                    BuildingCard(building: building, village: village, onUpgrade: { buildingID in
                        attemptUpgrade(buildingID: buildingID)
                    })
                }
            }
        }
    }

    func attemptUpgrade(buildingID: UUID) {
        var mutableVillage = village
        let engine = BuildingConstructionEngine()

        if engine.upgradeBuilding(buildingID: buildingID, in: &mutableVillage) {
            GameManager.shared.updateVillage(mutableVillage)
            onUpdate()
        }
    }

    var resourcesSection: some View {
        let globalResources = GameManager.shared.getGlobalResources(playerID: village.owner)
        return HStack(spacing: 6) {
            ForEach(Resource.getAll(), id: \.self) { resource in
                HStack(spacing: 1) {
                    Text(resource.emoji).font(.caption2)
                    Text("\(globalResources[resource] ?? 0)").font(.caption2).fontWeight(.medium)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color(.systemGray).opacity(0.2).opacity(0.5))
        .cornerRadius(4)
    }

    var stationedUnitsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Units").font(.caption).fontWeight(.semibold)
                Spacer()
                let unitsHere = GameManager.shared.map.getUnitsAt(point: village.coordinates)
                    .filter { $0.owner == village.owner }
                Text("\(unitsHere.count)").font(.caption2).foregroundColor(.secondary)
            }

            let unitsAtLocation = GameManager.shared.map.getUnitsAt(point: village.coordinates)
                .filter { $0.owner == village.owner }

            if unitsAtLocation.isEmpty {
                Text("No units").foregroundColor(.secondary).italic().font(.caption2)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(unitsAtLocation) { unit in
                            UnitMiniCard(unit: unit)
                        }
                    }
                }
            }
        }
    }

    var happinessIcon: String {
        let happiness = village.totalHappiness
        if happiness >= 80 { return "face.smiling.fill" }
        if happiness >= 50 { return "face.smiling" }
        return "face.dashed.fill"
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
                    .transition(.opacity.combined(with: .move(edge: .top)))
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
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct CompactStat: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundColor(.blue)
            Text(value).font(.caption).fontWeight(.medium)
        }
    }
}

struct BuildingCard: View {
    let building: Building
    let village: Village
    let onUpgrade: (UUID) -> Void

    var body: some View {
        let upgradeCheck = BuildingConstructionEngine().canUpgradeBuilding(building, in: village)
        let globalResources = GameManager.shared.getGlobalResources(playerID: village.owner)

        HStack(spacing: 8) {
            // Building icon + info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(buildingIcon)
                        .font(.title3)
                    Text(building.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                HStack(spacing: 8) {
                    Text("Level \(building.level)")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    // Show production/bonuses
                    if !building.resourcesProduction.isEmpty {
                        ForEach(Array(building.resourcesProduction.keys), id: \.self) { resource in
                            if let amount = building.resourcesProduction[resource] {
                                Text("\(resource.emoji)+\(amount)")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    if building.defenseBonus > 0 {
                        Text("🛡️+\(Int(building.defenseBonus * 100))%")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    if building.happinessBonus > 0 {
                        Text("😊+\(building.happinessBonus)")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            // Upgrade button (prominent!)
            if upgradeCheck.can {
                Button(action: { onUpgrade(building.id) }) {
                    VStack(spacing: 2) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text("Upgrade")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        // Show cost
                        HStack(spacing: 2) {
                            ForEach(Array(upgradeCheck.cost.keys.prefix(3)), id: \.self) { resource in
                                if let cost = upgradeCheck.cost[resource] {
                                    let has = globalResources[resource] ?? 0
                                    Text("\(resource.emoji)\(cost)")
                                        .font(.system(size: 9))
                                        .foregroundColor(has >= cost ? .secondary : .red)
                                }
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            } else {
                Text("Max")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
            }
        }
        .padding(8)
        .background(buildingColor.opacity(0.15))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(buildingColor.opacity(0.3), lineWidth: 1)
        )
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

    var buildingColor: Color {
        if !building.resourcesProduction.isEmpty {
            return Color.green
        } else if building.defenseBonus > 0 {
            return Color.blue
        } else if building.happinessBonus > 0 {
            return Color.orange
        } else if building.productionBonus > 0 {
            return Color.purple
        }
        return Color.gray
    }
}

struct UnitMiniCard: View {
    let unit: Unit

    var body: some View {
        VStack(spacing: 2) {
            Text(unit.unitType.emoji).font(.caption)
            Text(unit.name).font(.system(size: 7)).lineLimit(1)
            HStack(spacing: 4) {
                HStack(spacing: 1) {
                    Image(systemName: "sword.fill").font(.system(size: 6)).foregroundColor(.red)
                    Text("\(unit.attack)").font(.system(size: 6))
                }
                HStack(spacing: 1) {
                    Image(systemName: "shield.fill").font(.system(size: 6)).foregroundColor(.blue)
                    Text("\(unit.defense)").font(.system(size: 6))
                }
                HStack(spacing: 1) {
                    Image(systemName: "heart.fill").font(.system(size: 6)).foregroundColor(.green)
                    Text("\(unit.currentHP)").font(.system(size: 6))
                }
            }
            .foregroundColor(.secondary)
        }
        .padding(4)
        .background(Color(.systemGray).opacity(0.2))
        .cornerRadius(4)
    }
}
