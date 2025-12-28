//
//  RecruitMenuView.swift
//  VillagesTown
//
//  Created by Claude Code
//

import SwiftUI

// Inline version for use within VillageDetailView
struct RecruitMenuInlineView: View {
    let village: Village
    let onUpdate: () -> Void
    @State private var selectedUnitType: Unit.UnitType?
    @State private var showAlert = false
    @State private var alertMessage = ""

    let recruitmentEngine = RecruitmentEngine()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Available Units
                let availableUnits = recruitmentEngine.getAvailableUnits(for: village)

                if availableUnits.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("No military buildings")
                            .font(.headline)
                        Text("Build a Barracks or Archery Range to recruit units")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .transition(.scale.combined(with: .opacity))
                } else {
                    // Group by category
                    let unitsByCategory = Dictionary(grouping: availableUnits) { $0.category }

                    ForEach(Array(unitsByCategory.keys.sorted()), id: \.self) { category in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(category)
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(unitsByCategory[category] ?? [], id: \.self) { unitType in
                                UnitRecruitCard(
                                    unitType: unitType,
                                    village: village,
                                    onRecruit: { quantity in
                                        attemptRecruit(unitType: unitType, quantity: quantity)
                                    }
                                )
                                .padding(.horizontal)
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .alert("Recruitment", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    func attemptRecruit(unitType: Unit.UnitType, quantity: Int) {
        var mutableVillage = village
        let recruitedUnits = recruitmentEngine.recruitUnits(
            unitType: unitType,
            quantity: quantity,
            in: &mutableVillage,
            at: village.coordinates
        )

        if !recruitedUnits.isEmpty {
            // Update village
            GameManager.shared.updateVillage(mutableVillage)

            // Add units to map
            GameManager.shared.map.addUnits(recruitedUnits)

            // Post notification to refresh UI
            NotificationCenter.default.post(name: NSNotification.Name("MapUpdated"), object: nil)

            // Update parent view
            onUpdate()

            let stats = Unit.getStats(for: unitType)
            alertMessage = "Successfully recruited \(quantity) \(stats.name)!"
            showAlert = true
        } else {
            let check = recruitmentEngine.canRecruit(unitType: unitType, quantity: quantity, in: village)
            alertMessage = check.reason
            showAlert = true
        }
    }
}

// Original sheet version (kept for backwards compatibility)
struct RecruitMenuView: View {
    let village: Village
    @Binding var isPresented: Bool
    @State private var selectedUnitType: Unit.UnitType?
    @State private var showAlert = false
    @State private var alertMessage = ""

    let recruitmentEngine = RecruitmentEngine()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Recruit Units")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") {
                    isPresented = false
                }
            }
            .padding()
            .background(Color(white: 0.1))

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // Available Units
                    let availableUnits = recruitmentEngine.getAvailableUnits(for: village)

                    if availableUnits.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            Text("No military buildings")
                                .font(.headline)
                            Text("Build a Barracks or Archery Range to recruit units")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding()
                    } else {
                        // Group by category
                        let unitsByCategory = Dictionary(grouping: availableUnits) { $0.category }

                        ForEach(Array(unitsByCategory.keys.sorted()), id: \.self) { category in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(category)
                                    .font(.headline)
                                    .padding(.horizontal)

                                ForEach(unitsByCategory[category] ?? [], id: \.self) { unitType in
                                    UnitRecruitCard(
                                        unitType: unitType,
                                        village: village,
                                        onRecruit: { quantity in
                                            attemptRecruit(unitType: unitType, quantity: quantity)
                                        }
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .alert("Recruitment", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    func attemptRecruit(unitType: Unit.UnitType, quantity: Int) {
        var mutableVillage = village
        let recruitedUnits = recruitmentEngine.recruitUnits(
            unitType: unitType,
            quantity: quantity,
            in: &mutableVillage,
            at: village.coordinates
        )

        if !recruitedUnits.isEmpty {
            // Update village
            GameManager.shared.updateVillage(mutableVillage)

            // Add units to map
            GameManager.shared.map.addUnits(recruitedUnits)

            // Post notification to refresh UI
            NotificationCenter.default.post(name: NSNotification.Name("MapUpdated"), object: nil)

            let stats = Unit.getStats(for: unitType)
            alertMessage = "Successfully recruited \(quantity) \(stats.name)!"
            showAlert = true
        } else {
            let check = recruitmentEngine.canRecruit(unitType: unitType, quantity: quantity, in: village)
            alertMessage = check.reason
            showAlert = true
        }
    }
}

struct UnitRecruitCard: View {
    let unitType: Unit.UnitType
    let village: Village
    let onRecruit: (Int) -> Void
    @State private var quantity: Int = 1

    let recruitmentEngine = RecruitmentEngine()

    var unitStats: (name: String, attack: Int, defense: Int, hp: Int, movement: Int, cost: [Resource: Int], upkeep: [Resource: Int]) {
        Unit.getStats(for: unitType)
    }

    var recruitCheck: (can: Bool, reason: String) {
        recruitmentEngine.canRecruit(unitType: unitType, quantity: quantity, in: village)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(unitType.emoji)
                    .font(.title)

                VStack(alignment: .leading, spacing: 4) {
                    Text(unitStats.name)
                        .font(.headline)
                    HStack(spacing: 12) {
                        Label("\(unitStats.attack)", systemImage: "burst.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Label("\(unitStats.defense)", systemImage: "shield.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Label("\(unitStats.hp)", systemImage: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                Spacer()
            }

            // Cost display - clearer
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Total Cost:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Pop: \(quantity)")
                        .font(.caption)
                        .foregroundColor(village.population >= quantity ? .green : .red)
                }

                HStack(spacing: 12) {
                    ForEach(Array(unitStats.cost.keys.sorted(by: { $0.name < $1.name })), id: \.self) { resource in
                        let cost = unitStats.cost[resource]! * quantity
                        let globalResources = GameManager.shared.getGlobalResources(playerID: village.owner)
                        let has = globalResources[resource] ?? 0
                        let canAfford = has >= cost

                        VStack(spacing: 2) {
                            Text(resource.emoji)
                                .font(.title3)
                            Text("\(cost)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(canAfford ? .white : .red)
                            Text("/\(has)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(canAfford ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
            }

            // Quantity and Recruit
            HStack(spacing: 12) {
                // Quantity stepper
                HStack(spacing: 8) {
                    Button(action: {
                        if quantity > 1 { quantity -= 1 }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(quantity > 1 ? .blue : .gray)
                    }
                    .buttonStyle(.plain)
                    .disabled(quantity <= 1)

                    Text("\(quantity)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(width: 30)

                    Button(action: {
                        if quantity < min(10, village.population) {
                            quantity += 1
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(quantity < min(10, village.population) ? .blue : .gray)
                    }
                    .buttonStyle(.plain)
                    .disabled(quantity >= min(10, village.population))
                }

                // Recruit button with reason
                VStack(spacing: 4) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            onRecruit(quantity)
                        }
                    }) {
                        Text("RECRUIT")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(recruitCheck.can ? Color.blue : Color.gray.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(!recruitCheck.can)

                    // Show reason if can't recruit
                    if !recruitCheck.can {
                        Text(recruitCheck.reason)
                            .font(.caption2)
                            .foregroundColor(.red)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// Make Unit.UnitType hashable for ForEach
extension Unit.UnitType: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }
}
