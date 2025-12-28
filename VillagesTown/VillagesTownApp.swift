//
//  VillagesTownApp.swift
//  VillagesTown
//
//  SwiftUI App entry point for Universal (iOS, iPadOS, macOS Catalyst)
//

import SwiftUI

@main
struct VillagesTownApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1400, height: 900)
        #endif
    }
}
