//
//  UnitDetailView.swift
//  VillagesTown
//
//  Created by Claude Code
//

import SwiftUI

struct UnitDetailView: View {
    let units: [Unit]
    @Binding var isPresented: Bool
    @State private var selectedAction: UnitAction? = nil
    @State private var showingAlert = false
    @State private var alertMessage = ""

    enum UnitAction {
        case move
        case attack
        case fortify
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 20) {
                    // Army Header
                    armyHeader

                    Divider()

                    // Units List
                    unitsSection

                    // Actions (only for player units)
                    if units.first?.owner == "player" {
                        Divider()
                        actionsSection
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Army Details")
            .alert("Action Result", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    var armyHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(units.count) Units")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text("Owner: \(units.first?.owner ?? "Unknown")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 20) {
                let totalAttack = units.reduce(0) { $0 + $1.attack }
                let totalDefense = units.reduce(0) { $0 + $1.defense }
                let totalHP = units.reduce(0) { $0 + $1.currentHP }
                let maxHP = units.reduce(0) { $0 + $1.maxHP }

                StatBadge(icon: "sword.fill", value: "\(totalAttack)", label: "Attack", color: .red)
                StatBadge(icon: "shield.fill", value: "\(totalDefense)", label: "Defense", color: .blue)
                StatBadge(icon: "heart.fill", value: "\(totalHP)/\(maxHP)", label: "HP", color: .green)
            }
        }
    }

    var unitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Units")
                .font(.headline)

            ForEach(units) { unit in
                UnitRow(unit: unit)
            }
        }
    }

    var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)

            VStack(spacing: 12) {
                ActionButton(
                    icon: "arrow.right.circle.fill",
                    title: "Move Army",
                    description: "Move units to a new location",
                    color: .blue
                ) {
                    alertMessage = "Tap on a tile on the map to move there"
                    showingAlert = true
                }

                ActionButton(
                    icon: "sword.fill",
                    title: "Attack",
                    description: "Attack enemy units or village",
                    color: .red
                ) {
                    alertMessage = "Tap on an enemy to attack"
                    showingAlert = true
                }

                ActionButton(
                    icon: "shield.fill",
                    title: "Fortify",
                    description: "Skip movement for +25% defense",
                    color: .green
                ) {
                    alertMessage = "Units fortified! +25% defense until they move"
                    showingAlert = true
                }
            }
        }
    }
}

struct UnitRow: View {
    let unit: Unit

    var body: some View {
        HStack {
            Text(unit.unitType.emoji)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text(unit.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    Label("\(unit.attack)", systemImage: "sword.fill")
                        .font(.caption)
                    Label("\(unit.defense)", systemImage: "shield.fill")
                        .font(.caption)
                    Label("\(unit.currentHP)/\(unit.maxHP)", systemImage: "heart.fill")
                        .font(.caption)
                    Label("Lv.\(unit.level)", systemImage: "star.fill")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Movement")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(unit.movementRemaining)/\(unit.movement)")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray).opacity(0.2))
        .cornerRadius(10)
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray).opacity(0.2))
        .cornerRadius(10)
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray).opacity(0.2))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
