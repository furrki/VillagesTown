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
    @State private var showTrophy = false
    @State private var showTitle = false
    @State private var showStats = false
    @State private var showButton = false
    @State private var trophyRotation = 0.0

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onAppear {
                    animateEntrance()
                }

            VStack(spacing: 30) {
                // Trophy
                Text("🏆")
                    .font(.system(size: 100))
                    .opacity(showTrophy ? 1 : 0)
                    .scaleEffect(showTrophy ? 1.0 : 0.1)
                    .rotationEffect(.degrees(trophyRotation))
                    .shadow(color: .yellow.opacity(0.5), radius: 20)

                // Victory Text
                VStack(spacing: 10) {
                    Text("VICTORY!")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.yellow)
                        .opacity(showTitle ? 1 : 0)
                        .scaleEffect(showTitle ? 1.0 : 0.5)
                        .shadow(color: .yellow.opacity(0.5), radius: 10)

                    Text(winner.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 20)

                    Text("has conquered the world!")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 20)
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
                            .shadow(color: .green.opacity(0.3), radius: 8)
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
                .opacity(showStats ? 1 : 0)
                .offset(y: showStats ? 0 : 30)

                // Button
                Button(action: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isPresented = false
                    }
                }) {
                    Text("Continue Watching")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(Color.blue)
                        .cornerRadius(25)
                        .shadow(color: .blue.opacity(0.5), radius: 10)
                }
                .opacity(showButton ? 1 : 0)
                .scaleEffect(showButton ? 1.0 : 0.8)
            }
            .padding()
        }
    }

    func animateEntrance() {
        // Trophy animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
            showTrophy = true
        }

        // Continuous trophy rotation
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            trophyRotation = 360
        }

        // Title animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6)) {
            showTitle = true
        }

        // Stats animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.0)) {
            showStats = true
        }

        // Button animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.4)) {
            showButton = true
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
