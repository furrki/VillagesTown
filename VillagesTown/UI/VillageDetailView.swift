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
            .background(Color(NSColor.windowBackgroundColor))

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
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(4)

                // Resources in compact row
                resourcesSection

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
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Buildings").font(.caption).fontWeight(.semibold)
                let upgradeableCount = village.buildings.filter { building in
                    BuildingConstructionEngine().canUpgradeBuilding(building, in: village).can
                }.count
                if upgradeableCount > 0 {
                    Circle().fill(Color.green).frame(width: 6, height: 6)
                }
                Spacer()
                Text("\(village.buildings.count)/\(village.maxBuildings)").font(.caption2).foregroundColor(.secondary)
            }

            if village.buildings.isEmpty {
                Text("Empty").foregroundColor(.secondary).italic().font(.caption2)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 6), spacing: 3) {
                    ForEach(village.buildings) { building in
                        BuildingMicroSlot(building: building, village: village, onUpgrade: { buildingID in
                            attemptUpgrade(buildingID: buildingID)
                        })
                    }
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
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(4)
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
                BuildMenuInlineView(village: village)
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
                RecruitMenuInlineView(village: village)
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

struct BuildingMicroSlot: View {
    let building: Building
    let village: Village
    let onUpgrade: (UUID) -> Void

    var body: some View {
        let upgradeCheck = BuildingConstructionEngine().canUpgradeBuilding(building, in: village)
        let globalResources = GameManager.shared.getGlobalResources(playerID: village.owner)

        Button(action: {
            if upgradeCheck.can {
                onUpgrade(building.id)
            }
        }) {
            VStack(spacing: 1) {
                // Building name (abbreviated if needed)
                Text(building.name)
                    .font(.system(size: 9, weight: .semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 24)
                    .background(buildingColor)
                    .cornerRadius(3)

                // Level + upgrade indicator
                HStack(spacing: 2) {
                    Text("L\(building.level)")
                        .font(.system(size: 7))
                        .foregroundColor(.secondary)
                    if upgradeCheck.can {
                        Circle().fill(Color.green).frame(width: 3, height: 3)
                    }
                }

                // Upgrade cost
                if !upgradeCheck.cost.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(upgradeCheck.cost.keys.prefix(2)), id: \.self) { resource in
                            if let cost = upgradeCheck.cost[resource] {
                                let has = globalResources[resource] ?? 0
                                let canAfford = has >= cost
                                Text("\(resource.emoji)\(cost)")
                                    .font(.system(size: 6))
                                    .foregroundColor(canAfford ? .secondary : .red)
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .help(buildingTooltip)
    }

    var buildingColor: Color {
        if !building.resourcesProduction.isEmpty {
            return Color.green.opacity(0.7)
        } else if building.defenseBonus > 0 {
            return Color.blue.opacity(0.7)
        } else if building.happinessBonus > 0 {
            return Color.orange.opacity(0.7)
        } else if building.productionBonus > 0 {
            return Color.purple.opacity(0.7)
        }
        return Color.gray.opacity(0.7)
    }

    var buildingTooltip: String {
        var tooltip = building.name + " (Level \(building.level))"

        if !building.resourcesProduction.isEmpty {
            tooltip += "\n"
            for (resource, amount) in building.resourcesProduction {
                tooltip += "\(resource.emoji) +\(amount) "
            }
        }

        if building.productionBonus > 0 {
            tooltip += "\n📈 +\(Int(building.productionBonus * 100))%"
        }
        if building.defenseBonus > 0 {
            tooltip += "\n🛡️ +\(Int(building.defenseBonus * 100))%"
        }
        if building.happinessBonus > 0 {
            tooltip += "\n😊 +\(building.happinessBonus)"
        }

        return tooltip
    }
}

