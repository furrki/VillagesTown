//
//  VictoryScreenView.swift
//  VillagesTown
//
//  Created by Claude Code
//

import SwiftUI

struct VictoryScreenView: View {
    let winner: Player
    let turns: Int
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                // Trophy
                Text("🏆")
                    .font(.system(size: 100))

                // Victory Text
                VStack(spacing: 10) {
                    Text("VICTORY!")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.yellow)

                    Text(winner.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("has conquered the world!")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                }

                // Stats
                VStack(spacing: 15) {
                    StatRow(label: "Turns", value: "\(turns)")
                    StatRow(label: "Nationality", value: winner.nationality.flag + " " + winner.nationality.name)

                    if winner.isHuman {
                        Text("YOU WON!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .padding()
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(10)
                    } else {
                        Text("AI Victory")
                            .font(.title3)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(15)

                // Button
                Button(action: {
                    isPresented = false
                }) {
                    Text("Continue Watching")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(Color.blue)
                        .cornerRadius(25)
                }
            }
            .padding()
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}
