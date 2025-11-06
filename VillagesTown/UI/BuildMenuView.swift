//
//  BuildMenuView.swift
//  VillagesTown
//
//  Created by Claude Code
//

import SwiftUI

// Shared category enum
enum BuildingCategory: String, CaseIterable {
    case economic = "Economic"
    case military = "Military"
    case infrastructure = "Infrastructure"
    case special = "Special"

    var buildings: [Building] {
        switch self {
        case .economic: return Building.allEconomic
        case .military: return Building.allMilitary
        case .infrastructure: return Building.allInfrastructure
        case .special: return Building.allSpecial
        }
    }

    var icon: String {
        switch self {
        case .economic: return "banknote"
        case .military: return "shield.fill"
        case .infrastructure: return "building.2"
        case .special: return "star.fill"
        }
    }
}

// Inline version for use within VillageDetailView
struct BuildMenuInlineView: View {
    let village: Village
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(BuildingCategory.allCases, id: \.self) { category in
                let categoryBuildings = availableBuildings(for: category)
                if !categoryBuildings.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 2) {
                            Image(systemName: category.icon)
                                .font(.system(size: 7))
                                .foregroundColor(.secondary)
                            Text(category.rawValue)
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 6), spacing: 2) {
                            ForEach(categoryBuildings) { building in
                                CompactBuildingCard(
                                    building: building,
                                    village: village,
                                    onBuild: { buildBuilding in
                                        attemptBuild(buildBuilding)
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }
        .alert("Cannot Build", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    func availableBuildings(for category: BuildingCategory) -> [Building] {
        category.buildings.filter { building in
            !village.buildings.contains { existingBuilding in
                existingBuilding.name == building.name
            }
        }
    }

    func attemptBuild(_ building: Building) {
        var mutableVillage = village
        let engine = BuildingConstructionEngine()

        let result = engine.canBuild(building: building, in: mutableVillage)

        if result.can {
            if engine.buildBuilding(building: building, in: &mutableVillage) {
                GameManager.shared.updateVillage(mutableVillage)
                NotificationCenter.default.post(name: NSNotification.Name("MapUpdated"), object: nil)
            }
        } else {
            alertMessage = result.reason
            showAlert = true
        }
    }
}

// Original sheet version (kept for backwards compatibility)
struct BuildMenuView: View {
    let village: Village
    @Binding var isPresented: Bool
    @State private var selectedCategory: BuildingCategory = .economic
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Build")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") {
                    isPresented = false
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Category Picker
            categoryPicker

            // Buildings List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(selectedCategory.buildings) { building in
                        BuildingCard(
                            building: building,
                            village: village,
                            onBuild: { buildBuilding in
                                attemptBuild(buildBuilding)
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .alert("Build Result", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(BuildingCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                            Text(category.rawValue)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(selectedCategory == category ? Color.blue : Color(NSColor.controlBackgroundColor))
                        .foregroundColor(selectedCategory == category ? .white : .primary)
                        .cornerRadius(20)
                    }
                }
            }
            .padding()
        }
        .background(Color(NSColor.windowBackgroundColor))
        .shadow(radius: 1)
    }

    func attemptBuild(_ building: Building) {
        var mutableVillage = village
        let engine = BuildingConstructionEngine()

        let result = engine.canBuild(building: building, in: mutableVillage)

        if result.can {
            if engine.buildBuilding(building: building, in: &mutableVillage) {
                GameManager.shared.updateVillage(mutableVillage)
                // Post notification to refresh UI
                NotificationCenter.default.post(name: NSNotification.Name("MapUpdated"), object: nil)
                alertMessage = "Successfully built \(building.name)!"
                showAlert = true
            }
        } else {
            alertMessage = result.reason
            showAlert = true
        }
    }
}

struct CompactBuildingCard: View {
    let building: Building
    let village: Village
    let onBuild: (Building) -> Void

    var body: some View {
        Button(action: {
            onBuild(building)
        }) {
            VStack(spacing: 1) {
                // Building name
                Text(building.name)
                    .font(.system(size: 8, weight: .semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 20)
                    .background(canBuild ? Color.blue.opacity(0.8) : Color.gray.opacity(0.5))
                    .cornerRadius(3)

                // Cost
                let globalResources = GameManager.shared.getGlobalResources(playerID: village.owner)
                VStack(spacing: 0) {
                    ForEach(Array(building.baseCost.keys.sorted(by: { $0.name < $1.name }).prefix(2)), id: \.self) { resource in
                        let cost = building.baseCost[resource]!
                        let has = globalResources[resource] ?? 0
                        let canAfford = has >= cost

                        Text("\(resource.emoji)\(cost)")
                            .font(.system(size: 6))
                            .foregroundColor(canAfford ? .secondary : .red)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!canBuild)
        .help(building.description)
    }

    var canBuild: Bool {
        let engine = BuildingConstructionEngine()
        let result = engine.canBuild(building: building, in: village)
        return result.can
    }
}

struct BuildingCard: View {
    let building: Building
    let village: Village
    let onBuild: (Building) -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Name and description
            VStack(alignment: .leading, spacing: 2) {
                Text(building.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(building.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Cost
            HStack(spacing: 6) {
                let globalResources = GameManager.shared.getGlobalResources(playerID: village.owner)
                ForEach(Array(building.baseCost.keys.sorted(by: { $0.name < $1.name })), id: \.self) { resource in
                    let cost = building.baseCost[resource]!
                    let has = globalResources[resource] ?? 0
                    let canAfford = has >= cost

                    HStack(spacing: 2) {
                        Text(resource.emoji)
                        Text("\(cost)")
                    }
                    .font(.caption)
                    .foregroundColor(canAfford ? .primary : .red)
                }
            }

            // Build Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onBuild(building)
                }
            }) {
                Text("Build")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(canBuild ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .disabled(!canBuild)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    var canBuild: Bool {
        let engine = BuildingConstructionEngine()
        let result = engine.canBuild(building: building, in: village)
        return result.can
    }
}
