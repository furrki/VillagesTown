//
//  LayoutConstants.swift
//  VillagesTown
//
//  Responsive layout constants for Universal app
//

import SwiftUI

enum LayoutConstants {
    // MARK: - Device Detection

    static var isPhone: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .phone
        #else
        return false
        #endif
    }

    static var isPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return false
        #endif
    }

    static var isMac: Bool {
        #if os(macOS) || targetEnvironment(macCatalyst)
        return true
        #else
        return false
        #endif
    }

    // MARK: - Village Node Sizes

    static func villageNodeSize(compact: Bool) -> CGFloat {
        compact ? 72 : 64
    }

    static func villageNodeFontSize(compact: Bool) -> CGFloat {
        compact ? 36 : 32
    }

    // MARK: - Panel Widths

    static func sidePanelWidth(compact: Bool) -> CGFloat {
        compact ? .infinity : 340
    }

    // MARK: - Padding

    static func mapPadding(compact: Bool, size: CGSize) -> CGFloat {
        if compact {
            return min(size.width, size.height) * 0.08
        }
        return 80
    }

    static func contentPadding(compact: Bool) -> CGFloat {
        compact ? 12 : 20
    }

    // MARK: - Touch Targets

    static let minTouchTarget: CGFloat = 44

    // MARK: - Bottom Sheet Detents

    static let sheetCollapsedHeight: CGFloat = 120
    static let sheetMediumFraction: CGFloat = 0.45
    static let sheetLargeFraction: CGFloat = 0.85

    // MARK: - Font Sizes (scaled for mobile)

    static func captionSize(compact: Bool) -> CGFloat {
        compact ? 11 : 9
    }

    static func bodySize(compact: Bool) -> CGFloat {
        compact ? 15 : 13
    }

    static func headlineSize(compact: Bool) -> CGFloat {
        compact ? 18 : 16
    }

    // MARK: - Haptics

    #if os(iOS)
    static func selectionFeedback() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    static func impactFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    #else
    static func selectionFeedback() {}
    static func impactFeedback(style: Any? = nil) {}
    #endif
}

// MARK: - Environment Key for Compact Detection

struct IsCompactKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isCompact: Bool {
        get { self[IsCompactKey.self] }
        set { self[IsCompactKey.self] = newValue }
    }
}
