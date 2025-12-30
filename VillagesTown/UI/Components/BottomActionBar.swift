//
//  BottomActionBar.swift
//  VillagesTown
//
//  Fixed bottom action bar for mobile - always visible, no dragging
//

import SwiftUI

struct BottomActionBar: View {
    let selectedVillage: Village?
    let selectedArmy: Army?
    let isProcessingTurn: Bool
    let onEndTurn: () -> Void

    @ObservedObject var gameManager = GameManager.shared

    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            selectionIndicator
                .frame(maxWidth: .infinity, alignment: .leading)

            // End Turn button
            endTurnButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            MaterialEffectView(material: .systemThickMaterialDark)
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1),
            alignment: .top
        )
    }

    // MARK: - Selection Indicator

    @ViewBuilder
    var selectionIndicator: some View {
        if let village = selectedVillage {
            HStack(spacing: 10) {
                // Flag
                Text(village.nationality.flag)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(village.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Label("\(village.population)", systemImage: "person.fill")
                        Label("\(village.garrisonStrength)", systemImage: "shield.fill")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
                }
            }
        } else if let army = selectedArmy {
            HStack(spacing: 10) {
                Text(army.emoji)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(army.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(army.isMarching ? "Marching • \(army.turnsUntilArrival) turns" : "\(army.unitCount) units • \(army.strength) STR")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        } else {
            HStack(spacing: 10) {
                Image(systemName: "hand.tap")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.4))

                Text("Tap a village to select")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }

    // MARK: - End Turn Button

    var endTurnButton: some View {
        Button(action: {
            LayoutConstants.impactFeedback(style: .medium)
            onEndTurn()
        }) {
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
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isProcessingTurn ? Color.orange : Color.blue)
            )
            .shadow(color: .blue.opacity(0.4), radius: 8, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isProcessingTurn)
    }
}

// MARK: - Collapsible Resource HUD

struct CollapsibleResourceHUD: View {
    let turn: Int
    let resources: [Resource: Int]
    let playerVillages: Int
    let totalVillages: Int

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Main compact bar
            HStack(spacing: 12) {
                // Turn indicator
                turnPill

                // Resources (collapsed = icons only, expanded = full)
                if isExpanded {
                    expandedResources
                } else {
                    collapsedResources
                }

                Spacer()

                // Victory progress
                victoryPill

                // Expand/collapse toggle
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(glassBackground)
        }
    }

    var turnPill: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 32, height: 32)

                Text("\(turn)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    Text(getCurrentSeason().uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                    Text("Year \(1000 + turn/4)")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
    }

    var collapsedResources: some View {
        HStack(spacing: 10) {
            ForEach(Array(Resource.getAll().prefix(4)), id: \.self) { resource in
                HStack(spacing: 3) {
                    Text(resource.emoji)
                        .font(.system(size: 12))
                    Text("\(resources[resource] ?? 0)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(resourceColor(for: resource))
                }
            }
        }
    }

    var expandedResources: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Resource.getAll(), id: \.self) { (resource: Resource) in
                    VStack(spacing: 2) {
                        Text(resource.emoji)
                            .font(.system(size: 14))
                        Text("\(resources[resource] ?? 0)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(resourceColor(for: resource))
                        Text(resource.name)
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
        }
    }

    var victoryPill: some View {
        let progress = CGFloat(playerVillages) / CGFloat(max(totalVillages, 1))
        return HStack(spacing: 4) {
            Image(systemName: "flag.fill")
                .font(.system(size: 10))
                .foregroundColor(.green)
            Text("\(playerVillages)/\(totalVillages)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.green.opacity(0.2))
                .overlay(
                    GeometryReader { geo in
                        Capsule()
                            .fill(Color.green.opacity(0.4))
                            .frame(width: geo.size.width * progress)
                    }
                )
        )
    }

    var glassBackground: some View {
        MaterialEffectView(material: .systemUltraThinMaterialDark)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.2), radius: 8)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }

    func resourceColor(for resource: Resource) -> Color {
        let amount = resources[resource] ?? 0
        if amount < 5 { return .red }
        if amount < 20 { return .orange }
        return .white
    }

    func getCurrentSeason() -> String {
        let seasons = ["Spring", "Summer", "Autumn", "Winter"]
        return seasons[(max(turn, 1) - 1) % 4]
    }
}
