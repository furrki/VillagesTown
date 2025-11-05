//
//  GameView.swift
//  VillagesTown
//
//  Created by Claude Code
//

import SwiftUI

struct GameView: View {
    @ObservedObject var gameManager = GameManager.shared
    @State private var selectedVillage: Village?
    @State private var showBuildMenu = false
    @State private var showVillageDetail = false
    @State private var showVictoryScreen = false

    var winner: Player? {
        let activePlayers = gameManager.players.filter { !$0.isEliminated }
        return activePlayers.count == 1 ? activePlayers.first : nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar - Resources and Info
            topBar

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
        .sheet(isPresented: $showVillageDetail) {
            if let village = selectedVillage {
                VillageDetailView(village: village, isPresented: $showVillageDetail)
            }
        }
        .overlay(
            Group {
                if let winner = winner {
                    VictoryScreenView(winner: winner, turns: gameManager.currentTurn, isPresented: $showVictoryScreen)
                        .onAppear {
                            showVictoryScreen = true
                        }
                }
            }
        )
        .onChange(of: gameManager.currentTurn) { _ in
            // Check for victory after each turn
            if winner != nil {
                showVictoryScreen = true
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

                Spacer()

                Text("🇹🇷 Your Empire")
                    .font(.headline)

                Spacer()

                Button(action: {
                    gameManager.toggleTutorial()
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
        .background(Color(UIColor.systemBackground))
        .shadow(radius: 2)
    }

    var bottomBar: some View {
        HStack(spacing: 16) {
            Button(action: {
                gameManager.turnEngine.doTurn()
            }) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                    Text("Next Turn")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            Spacer()

            if let village = selectedVillage {
                Text("Selected: \(village.name)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button("Details") {
                    showVillageDetail = true
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
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

    var body: some View {
        VStack(spacing: 4) {
            Text(resource.emoji)
                .font(.title3)
            Text("\(amount)")
                .font(.caption)
                .fontWeight(.semibold)
            Text(resource.name)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
}
