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
                        Text("Build a Barracks, Archery Range, or Cavalry Stable to recruit units")
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
            .background(Color(NSColor.windowBackgroundColor))

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
                            Text("Build a Barracks, Archery Range, or Cavalry Stable to recruit units")
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
                        Label("\(unitStats.attack)", systemImage: "sword.fill")
                            .font(.caption)
                        Label("\(unitStats.defense)", systemImage: "shield.fill")
                            .font(.caption)
                        Label("\(unitStats.hp) HP", systemImage: "heart.fill")
                            .font(.caption)
                        Label("\(unitStats.movement) Move", systemImage: "figure.walk")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                Spacer()
            }

            Divider()

            // Cost
            VStack(alignment: .leading, spacing: 6) {
                Text("Cost (per unit):")
                    .font(.subheadline)
                    .fontWeight(.medium)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(Array(unitStats.cost.keys.sorted(by: { $0.name < $1.name })), id: \.self) { resource in
                        let cost = unitStats.cost[resource]! * quantity
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

            // Upkeep
            VStack(alignment: .leading, spacing: 4) {
                Text("Upkeep (per turn):")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 8) {
                    ForEach(Array(unitStats.upkeep.keys.sorted(by: { $0.name < $1.name })), id: \.self) { resource in
                        HStack(spacing: 2) {
                            Text(resource.emoji)
                            Text("\(unitStats.upkeep[resource]!)")
                        }
                        .font(.caption2)
                    }
                }
            }

            // Quantity and Recruit
            HStack(spacing: 16) {
                // Quantity stepper
                HStack {
                    Button(action: {
                        if quantity > 1 { quantity -= 1 }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                    }
                    .disabled(quantity <= 1)

                    Text("\(quantity)")
                        .font(.headline)
                        .frame(width: 40)

                    Button(action: {
                        if quantity < min(10, village.population) {
                            quantity += 1
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .disabled(quantity >= min(10, village.population))
                }

                // Recruit button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onRecruit(quantity)
                    }
                }) {
                    Text("Recruit")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(canRecruit ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!canRecruit)
                .scaleEffect(canRecruit ? 1.0 : 0.95)
                .animation(.easeInOut(duration: 0.2), value: canRecruit)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    var canRecruit: Bool {
        let check = recruitmentEngine.canRecruit(unitType: unitType, quantity: quantity, in: village)
        return check.can
    }
}

// Make Unit.UnitType hashable for ForEach
extension Unit.UnitType: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }
}
