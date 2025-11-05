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
    @State private var selectedTab: Tab = .overview

    enum Tab: String, CaseIterable {
        case overview = "Overview"
        case build = "Build"
        case recruit = "Recruit"

        var icon: String {
            switch self {
            case .overview: return "info.circle.fill"
            case .build: return "hammer.fill"
            case .recruit: return "person.3.fill"
            }
        }
    }

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

            // Tab Selector
            tabSelector

            Divider()

            // Content based on selected tab
            Group {
                switch selectedTab {
                case .overview:
                    overviewContent
                case .build:
                    buildContent
                case .recruit:
                    recruitContent
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
    }

    var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.title3)
                        Text(tab.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedTab == tab ? Color.blue.opacity(0.1) : Color.clear)
                    .foregroundColor(selectedTab == tab ? .blue : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }

    var overviewContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Village Header
                villageHeader
                    .transition(.scale.combined(with: .opacity))

                Divider()

                // Stats
                villageStats
                    .transition(.scale.combined(with: .opacity))

                Divider()

                // Buildings
                buildingsSection
                    .transition(.scale.combined(with: .opacity))

                Divider()

                // Resources
                resourcesSection
                    .transition(.scale.combined(with: .opacity))

                Spacer()
            }
            .padding()
        }
    }

    var buildContent: some View {
        BuildMenuInlineView(village: village)
    }

    var recruitContent: some View {
        RecruitMenuInlineView(village: village)
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
                    BuildingRow(building: building)
                }
            }
        }
    }

    var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resources")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Resource.getAll(), id: \.self) { resource in
                    ResourceCard(resource: resource, amount: village.resources[resource] ?? 0)
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

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(building.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(building.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("Lv.\(building.level)")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(6)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
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
