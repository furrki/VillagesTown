//
//  AdaptiveGameView.swift
//  VillagesTown
//
//  Adaptive container that shows mobile or desktop layout based on device
//

import SwiftUI

struct AdaptiveGameView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        Group {
            if isCompact {
                // iPhone: Full-screen map + bottom sheet
                MobileGameLayout()
            } else {
                // iPad/Mac: Side panel layout (desktop)
                GameView()
            }
        }
        .environment(\.isCompact, isCompact)
    }
}

#Preview("iPhone") {
    AdaptiveGameView()
        .environment(\.horizontalSizeClass, .compact)
}

#Preview("iPad") {
    AdaptiveGameView()
        .environment(\.horizontalSizeClass, .regular)
}
