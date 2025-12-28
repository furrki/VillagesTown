//
//  FloatingHUD.swift
//  VillagesTown
//
//  Compact floating HUD for mobile showing turn and resources
//

import SwiftUI

struct FloatingHUD: View {
    let turn: Int
    let resources: [Resource: Int]
    let playerVillages: Int
    let totalVillages: Int
    
    // Glassmorphism background
    var glassBackground: some View {
        MaterialEffectView(material: .systemUltraThinMaterialDark)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(LinearGradient(
                        colors: [.white.opacity(0.2), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 1)
            )
    }

    var body: some View {
        HStack(spacing: 16) {
            // Turn Pill
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 36, height: 36)
                        .shadow(color: .blue.opacity(0.4), radius: 4, y: 2)
                    
                    Text("\(turn)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(getCurrentSeason().uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundColor(.white.opacity(0.6))
                    Text("YEAR \(1000 + turn/4)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.leading, 6)
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1, height: 24)
            
            // Resources Scroller (to save space)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Resource.getAll(), id: \.self) { resource in
                        CompactResourceView(
                            emoji: resource.emoji,
                            amount: resources[resource] ?? 0
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1, height: 24)
            
            // Victory Status
            CompactVictoryView(
                playerVillages: playerVillages,
                totalVillages: totalVillages
            )
            .padding(.trailing, 8)
        }
        .padding(8)
        .background(glassBackground)
    }

    func getCurrentSeason() -> String {
        let seasons = ["Spring", "Summer", "Autumn", "Winter"]
        let t = max(turn, 1)
        return seasons[(t - 1) % 4]
    }
}

struct CompactResourceView: View {
    let emoji: String
    let amount: Int

    var isLow: Bool { amount < 20 }
    var isCritical: Bool { amount < 5 }

    var body: some View {
        HStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 14))
                .shadow(radius: 2)
            Text("\(amount)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(isCritical ? .red : (isLow ? .orange : .white))
        }
    }
}

struct CompactVictoryView: View {
    let playerVillages: Int
    let totalVillages: Int

    var progress: CGFloat {
        CGFloat(playerVillages) / CGFloat(max(totalVillages, 1))
    }

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.8))
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // Custom Progress Bar
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 40, height: 4)
                
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 40 * progress, height: 4)
                    .shadow(color: .green.opacity(0.5), radius: 2)
            }
        }
    }
}

// UIVisualEffectView wrapper for SwiftUI
struct MaterialEffectView: UIViewRepresentable {
    let material: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: material))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: material)
    }
}

struct FloatingHUD_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.blue // background to see glass effect
            FloatingHUD(
                turn: 5,
                resources: [.food: 120, .wood: 45, .gold: 15],
                playerVillages: 2,
                totalVillages: 10
            )
        }
    }
}
