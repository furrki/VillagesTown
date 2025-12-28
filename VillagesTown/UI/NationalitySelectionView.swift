//
//  NationalitySelectionView.swift
//  VillagesTown
//
//  Created by Claude Code
//

import SwiftUI

struct NationalitySelectionView: View {
    @Binding var selectedNationality: Nationality?
    @Binding var isPresented: Bool
    var onSelection: ((Nationality) -> Void)?

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var hoveredNationality: String?
    @State private var showContent = false

    var isCompact: Bool { horizontalSizeClass == .compact }

    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.1, blue: 0.15),
                    Color(red: 0.12, green: 0.14, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle pattern overlay
            Canvas { context, size in
                for x in stride(from: 0, to: size.width, by: 50) {
                    for y in stride(from: 0, to: size.height, by: 50) {
                        let rect = CGRect(x: x, y: y, width: 1, height: 1)
                        context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.02)))
                    }
                }
            }

            ScrollView {
                VStack(spacing: isCompact ? 24 : 40) {
                    // Header
                    VStack(spacing: 12) {
                        Text("⚔️")
                            .font(.system(size: isCompact ? 48 : 60))
                            .opacity(showContent ? 1 : 0)
                            .scaleEffect(showContent ? 1 : 0.5)

                        Text("Choose Your Empire")
                            .font(.system(size: isCompact ? 28 : 42, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)

                        Text("Lead your nation to glory")
                            .font(isCompact ? .body : .title3)
                            .foregroundColor(.white.opacity(0.6))
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                    }

                    // Nation cards - vertical on mobile, horizontal on desktop
                    Group {
                        if isCompact {
                            VStack(spacing: 16) {
                                ForEach(Nationality.getAll(), id: \.name) { nationality in
                                    nationCardView(for: nationality)
                                }
                            }
                        } else {
                            HStack(spacing: 24) {
                                ForEach(Nationality.getAll(), id: \.name) { nationality in
                                    nationCardView(for: nationality)
                                }
                            }
                        }
                    }

                    // Footer hint
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.white.opacity(0.4))
                        Text("Each nation starts with unique territory")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .opacity(showContent ? 1 : 0)
                }
                .padding(isCompact ? 20 : 40)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                showContent = true
            }
        }
    }

    @ViewBuilder
    func nationCardView(for nationality: Nationality) -> some View {
        NationCard(
            nationality: nationality,
            isHovered: hoveredNationality == nationality.name,
            isCompact: isCompact,
            onSelect: {
                LayoutConstants.impactFeedback()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    onSelection?(nationality)
                    selectedNationality = nationality
                    isPresented = false
                }
            }
        )
        #if os(macOS)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                hoveredNationality = hovering ? nationality.name : nil
            }
        }
        #endif
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 30)
    }
}

struct NationCard: View {
    let nationality: Nationality
    let isHovered: Bool
    var isCompact: Bool = false
    let onSelect: () -> Void

    var nationColor: Color {
        switch nationality.name {
        case "Turkish": return Color(red: 0.8, green: 0.2, blue: 0.2)
        case "Greek": return Color(red: 0.2, green: 0.4, blue: 0.8)
        case "Bulgarian": return Color(red: 0.2, green: 0.6, blue: 0.3)
        default: return .gray
        }
    }

    var capitalName: String {
        switch nationality.name {
        case "Turkish": return "Istanbul"
        case "Greek": return "Athens"
        case "Bulgarian": return "Sofia"
        default: return "Capital"
        }
    }

    var body: some View {
        Button(action: onSelect) {
            Group {
                if isCompact {
                    // Horizontal layout for mobile
                    HStack(spacing: 16) {
                        // Flag
                        ZStack {
                            Circle()
                                .fill(nationColor.opacity(0.2))
                                .frame(width: 70, height: 70)
                                .blur(radius: 8)

                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [nationColor, nationColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .shadow(color: nationColor.opacity(0.5), radius: 8)

                            Text(nationality.flag)
                                .font(.system(size: 32))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(nationality.name)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            HStack(spacing: 4) {
                                Image(systemName: "building.columns.fill")
                                    .font(.caption2)
                                Text(capitalName)
                                    .font(.caption)
                            }
                            .foregroundColor(.white.opacity(0.6))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .foregroundColor(nationColor)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(nationColor.opacity(0.3), lineWidth: 1)
                            )
                    )
                } else {
                    // Vertical layout for desktop
                    VStack(spacing: 20) {
                        // Flag
                        ZStack {
                            Circle()
                                .fill(nationColor.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .blur(radius: isHovered ? 20 : 10)

                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [nationColor, nationColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .shadow(color: nationColor.opacity(0.5), radius: isHovered ? 20 : 10)

                            Text(nationality.flag)
                                .font(.system(size: 50))
                        }

                        // Info
                        VStack(spacing: 8) {
                            Text(nationality.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            HStack(spacing: 4) {
                                Image(systemName: "building.columns.fill")
                                    .font(.caption)
                                Text(capitalName)
                                    .font(.subheadline)
                            }
                            .foregroundColor(.white.opacity(0.6))
                        }

                        // Select button
                        Text("SELECT")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(isHovered ? nationColor : Color.white.opacity(0.1))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(nationColor.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .padding(30)
                    .frame(width: 220)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        isHovered ? nationColor.opacity(0.5) : Color.white.opacity(0.1),
                                        lineWidth: isHovered ? 2 : 1
                                    )
                            )
                    )
                    .scaleEffect(isHovered ? 1.05 : 1.0)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
