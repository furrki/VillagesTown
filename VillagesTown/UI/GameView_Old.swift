//
//  GameView.swift
//  VillagesTown
//
//  Created by Claude Code
//

import SwiftUI

struct GameView: View {
    @ObservedObject var gameManager = GameManager.shared
    @State private var showVictoryScreen = false
    @State private var isProcessingTurn = false
    @State private var showTutorial = true

    var winner: Player? {
        let activePlayers = gameManager.players.filter { !$0.isEliminated }
        return activePlayers.count == 1 ? activePlayers.first : nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar - Resources and Info
            topBar
                .animation(.easeInOut(duration: 0.3), value: gameManager.currentTurn)

            // Main Map View
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                MapView()
                    .frame(width: CGFloat(gameManager.map.size.width) * 25,
                           height: CGFloat(gameManager.map.size.height) * 25)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom Control Panel
            bottomBar
        }
        .onAppear {
            if !gameManager.gameStarted {
                gameManager.initializeGame()
            }
        }
        .overlay(
            Group {
                if let winner = winner, showVictoryScreen {
                    VictoryScreenView(winner: winner, turns: gameManager.currentTurn, isPresented: $showVictoryScreen)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        )
        .overlay(
            Group {
                if showTutorial && gameManager.currentTurn == 1 && gameManager.tutorialEnabled {
                    TutorialOverlay(isPresented: $showTutorial)
                        .transition(.opacity.combined(with: .scale))
                }
            }
        )
        .onChange(of: gameManager.currentTurn) { _ in
            // Check for victory after each turn
            if winner != nil {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showVictoryScreen = true
                }
            }
        }
    }

    var topBar: some View {
        VStack(spacing: 8) {
            // Turn and Player Info
            HStack {
                Text("Turn \(gameManager.currentTurn)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
                    .shadow(color: .blue.opacity(0.3), radius: 4)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: gameManager.currentTurn)

                Spacer()

                // Objective Display
                let enemyVillages = gameManager.map.villages.filter { $0.owner != "player" }
                VStack(spacing: 2) {
                    Text("🎯 Objective: Conquer all enemy villages")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("Enemies: \(enemyVillages.count) villages remaining")
                        .font(.caption2)
                        .foregroundColor(enemyVillages.isEmpty ? .green : .orange)
                }

                Spacer()

                Text("🇹🇷 Your Empire")
                    .font(.headline)

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        gameManager.toggleTutorial()
                    }
                }) {
                    Image(systemName: gameManager.tutorialEnabled ? "book.fill" : "book")
                        .font(.title2)
                }
            }
            .padding(.horizontal)

            // Resources
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    let playerVillages = gameManager.getPlayerVillages(playerID: "player")
                    let totalResources = calculateTotalResources(villages: playerVillages)

                    ForEach(Resource.getAll(), id: \.self) { resource in
                        ResourceBadge(
                            resource: resource,
                            amount: totalResources[resource] ?? 0
                        )
                    }
                }
                .padding(.horizontal)
            }

            // Population & Happiness
            HStack(spacing: 20) {
                let playerVillages = gameManager.getPlayerVillages(playerID: "player")
                let totalPop = playerVillages.reduce(0) { $0 + $1.population }
                let avgHappiness = playerVillages.isEmpty ? 0 : playerVillages.reduce(0) { $0 + $1.totalHappiness } / playerVillages.count
                let playerUnits = gameManager.map.units.filter { $0.owner == "player" }

                Label("\(totalPop)", systemImage: "person.3.fill")
                Label("\(avgHappiness)%", systemImage: happinessIcon(for: avgHappiness))
                Label("\(playerVillages.count) Villages", systemImage: "house.fill")
                Label("\(playerUnits.count) Units", systemImage: "figure.walk")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
        .shadow(radius: 2)
    }

    var bottomBar: some View {
        HStack(spacing: 16) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isProcessingTurn = true
                }

                // Delay to show animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    gameManager.turnEngine.doTurn()

                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isProcessingTurn = false
                    }
                }
            }) {
                HStack {
                    Image(systemName: isProcessingTurn ? "hourglass" : "arrow.right.circle.fill")
                        .font(.title2)
                        .rotationEffect(.degrees(isProcessingTurn ? 360 : 0))
                        .animation(isProcessingTurn ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isProcessingTurn)
                    Text(isProcessingTurn ? "Processing..." : "Next Turn")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(isProcessingTurn ? Color.orange : Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(color: (isProcessingTurn ? Color.orange : Color.green).opacity(0.4), radius: 6)
            }
            .disabled(isProcessingTurn)
            .scaleEffect(isProcessingTurn ? 0.95 : 1.0)

            Spacer()
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .shadow(radius: 2)
    }

    func calculateTotalResources(villages: [Village]) -> [Resource: Int] {
        var total: [Resource: Int] = [:]
        for village in villages {
            for (resource, amount) in village.resources {
                total[resource, default: 0] += amount
            }
        }
        return total
    }

    func happinessIcon(for happiness: Int) -> String {
        if happiness >= 80 { return "face.smiling.fill" }
        if happiness >= 50 { return "face.smiling" }
        return "face.dashed.fill"
    }
}

struct ResourceBadge: View {
    let resource: Resource
    let amount: Int
    @State private var previousAmount: Int = 0
    @State private var isChanged = false

    var body: some View {
        VStack(spacing: 4) {
            Text(resource.emoji)
                .font(.title3)
            Text("\(amount)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isChanged ? (amount > previousAmount ? .green : .red) : .primary)
                .animation(.easeInOut(duration: 0.3), value: isChanged)
            Text(resource.name)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .scaleEffect(isChanged ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isChanged)
        .onChange(of: amount) { newAmount in
            if previousAmount != 0 && newAmount != previousAmount {
                withAnimation {
                    isChanged = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        isChanged = false
                    }
                }
            }
            previousAmount = newAmount
        }
        .onAppear {
            previousAmount = amount
        }
    }
}

struct TutorialOverlay: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            // Tutorial card
            VStack(spacing: 20) {
                Text("🎮 How to Play")
                    .font(.title)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 12) {
                    TutorialStep(icon: "🏘️", text: "Click your green village to build and recruit")
                    TutorialStep(icon: "🏗️", text: "Build Farms for food, Barracks for units")
                    TutorialStep(icon: "⚔️", text: "Recruit units to defend and attack")
                    TutorialStep(icon: "🚶", text: "Tap your units to select, then tap a green tile to move")
                    TutorialStep(icon: "💥", text: "Move next to enemy villages (red) and tap them to attack")
                    TutorialStep(icon: "🎯", text: "Goal: Conquer all enemy villages to win!")
                    TutorialStep(icon: "⏭️", text: "Press 'Next Turn' when ready")
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPresented = false
                    }
                }) {
                    Text("Got it!")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(10)
                }
            }
            .padding(30)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(20)
            .shadow(radius: 20)
            .frame(maxWidth: 500)
        }
    }
}

struct TutorialStep: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(.title2)
            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
