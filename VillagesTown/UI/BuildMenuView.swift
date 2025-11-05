//
//  BuildMenuView.swift
//  VillagesTown
//
//  Created by Claude Code
//

import SwiftUI

struct BuildMenuView: View {
    let village: Village
    @Binding var isPresented: Bool
    @State private var selectedCategory: BuildingCategory = .economic
    @State private var showAlert = false
    @State private var alertMessage = ""

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
                alertMessage = "Successfully built \(building.name)!"
                showAlert = true
            }
        } else {
            alertMessage = result.reason
            showAlert = true
        }
    }
}

struct BuildingCard: View {
    let building: Building
    let village: Village
    let onBuild: (Building) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.headline)
                    Text(building.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            // Cost
            VStack(alignment: .leading, spacing: 6) {
                Text("Cost:")
                    .font(.subheadline)
                    .fontWeight(.medium)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(Array(building.baseCost.keys), id: \.self) { resource in
                        let cost = building.baseCost[resource]!
                        let has = village.resources[resource] ?? 0
                        let canAfford = has >= cost

                        HStack(spacing: 4) {
                            Text(resource.emoji)
                            Text("\(cost)")
                                .font(.caption)
                                .foregroundColor(canAfford ? .primary : .red)
                            Text("(\(has))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Bonuses
            if building.productionBonus > 0 || building.defenseBonus > 0 || building.happinessBonus > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bonuses:")
                        .font(.caption)
                        .fontWeight(.medium)
                    HStack(spacing: 12) {
                        if building.productionBonus > 0 {
                            Label("+\(Int(building.productionBonus * 100))% Production", systemImage: "chart.line.uptrend.xyaxis")
                                .font(.caption2)
                        }
                        if building.defenseBonus > 0 {
                            Label("+\(Int(building.defenseBonus * 100))% Defense", systemImage: "shield")
                                .font(.caption2)
                        }
                        if building.happinessBonus > 0 {
                            Label("+\(building.happinessBonus) Happiness", systemImage: "face.smiling")
                                .font(.caption2)
                        }
                    }
                }
            }

            // Build Button
            Button(action: {
                onBuild(building)
            }) {
                Text("Build")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(canBuild ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(!canBuild)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    var canBuild: Bool {
        let engine = BuildingConstructionEngine()
        return engine.canBuild(building: building, in: village).can
    }
}
