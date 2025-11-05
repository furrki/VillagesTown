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
    @State private var showBuildSection = false
    @State private var showRecruitSection = false

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
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Content
            overviewContent
        }
    }

    var overviewContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Village Header
                villageHeader

                // Stats and Resources side by side
                HStack(alignment: .top, spacing: 16) {
                    villageStats
                        .frame(maxWidth: .infinity)
                    resourcesSection
                        .frame(maxWidth: .infinity)
                }

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
            .padding()
        }
    }

    var villageHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(village.nationality.flag)
                    .font(.system(size: 50))
                VStack(alignment: .leading) {
                    Text(village.name)
                        .font(.title)
                        .fontWeight(.bold)
                    Text(village.level.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }

    var villageStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(icon: "person.3.fill", label: "Population", value: "\(village.population)/\(village.populationCapacity)")
                StatCard(icon: happinessIcon, label: "Happiness", value: "\(village.totalHappiness)%")
                StatCard(icon: "shield.fill", label: "Defense", value: "+\(Int(village.defenseBonus * 100))%")
                StatCard(icon: "chart.line.uptrend.xyaxis", label: "Production", value: "+\(Int(village.productionBonus * 100))%")
            }
        }
    }

    var buildingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Buildings")
                    .font(.headline)

                // Upgrade available badge
                let upgradeableCount = village.buildings.filter { building in
                    BuildingConstructionEngine().canUpgradeBuilding(building, in: village).can
                }.count

                if upgradeableCount > 0 {
                    Text("\(upgradeableCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .cornerRadius(8)
                }

                Spacer()
                Text("\(village.buildings.count)/\(village.maxBuildings)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if village.buildings.isEmpty {
                Text("No buildings yet")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(village.buildings) { building in
                    BuildingRow(building: building, village: village, onUpgrade: { buildingID in
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Empire Resources")
                .font(.headline)
                .foregroundColor(.green)

            let globalResources = GameManager.shared.getGlobalResources(playerID: village.owner)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Resource.getAll(), id: \.self) { resource in
                    ResourceCard(resource: resource, amount: globalResources[resource] ?? 0)
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
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showBuildSection.toggle()
                }
            }) {
                HStack {
                    Text("Build New")
                        .font(.headline)
                    Spacer()
                    Image(systemName: showBuildSection ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)

            if showBuildSection {
                BuildMenuInlineView(village: village)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    var recruitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showRecruitSection.toggle()
                }
            }) {
                HStack {
                    Text("Recruit Units")
                        .font(.headline)
                    Spacer()
                    Image(systemName: showRecruitSection ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)

            if showRecruitSection {
                RecruitMenuInlineView(village: village)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct StatCard: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            Spacer()
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct BuildingRow: View {
    let building: Building
    let village: Village
    let onUpgrade: (UUID) -> Void
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        HStack(spacing: 12) {
            // Name and Level
            VStack(alignment: .leading, spacing: 2) {
                Text(building.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                // Production info
                if !building.resourcesProduction.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(Array(building.resourcesProduction.keys.prefix(3)), id: \.self) { resource in
                            if let amount = building.resourcesProduction[resource] {
                                HStack(spacing: 2) {
                                    Text(resource.emoji)
                                    Text("+\(amount)")
                                }
                                .font(.caption2)
                                .foregroundColor(.green)
                            }
                        }
                    }
                } else if building.productionBonus > 0 || building.defenseBonus > 0 || building.happinessBonus > 0 {
                    HStack(spacing: 6) {
                        if building.productionBonus > 0 {
                            Text("+\(Int(building.productionBonus * 100))%📈")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                        if building.defenseBonus > 0 {
                            Text("+\(Int(building.defenseBonus * 100))%🛡️")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        if building.happinessBonus > 0 {
                            Text("+\(building.happinessBonus)😊")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }

            Spacer()

            // Level indicator
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { level in
                    Circle()
                        .fill(level <= building.level ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }

            // Upgrade button
            let upgradeCheck = BuildingConstructionEngine().canUpgradeBuilding(building, in: village)
            let globalResources = GameManager.shared.getGlobalResources(playerID: village.owner)
            Button(action: {
                if upgradeCheck.can {
                    onUpgrade(building.id)
                } else {
                    alertMessage = upgradeCheck.reason
                    showAlert = true
                }
            }) {
                VStack(spacing: 2) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title3)
                    if !upgradeCheck.cost.isEmpty {
                        HStack(spacing: 2) {
                            ForEach(Array(upgradeCheck.cost.keys.prefix(2)), id: \.self) { resource in
                                if let cost = upgradeCheck.cost[resource] {
                                    let has = globalResources[resource] ?? 0
                                    let canAfford = has >= cost
                                    HStack(spacing: 1) {
                                        Text(resource.emoji)
                                        Text("\(cost)")
                                    }
                                    .font(.caption2)
                                    .foregroundColor(canAfford ? .primary : .red)
                                }
                            }
                        }
                    }
                }
                .padding(6)
                .background(upgradeCheck.can ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(!upgradeCheck.can)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .alert("Upgrade", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}

struct ResourceCard: View {
    let resource: Resource
    let amount: Int

    var body: some View {
        VStack(spacing: 6) {
            Text(resource.emoji)
                .font(.title2)
            Text("\(amount)")
                .font(.headline)
                .fontWeight(.bold)
            Text(resource.name)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}
