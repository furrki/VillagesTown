//
//  MapView.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 23.06.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import SwiftUI
import Combine

struct MapView: View {
    @ObservedObject var viewModel: MapViewModel = MapViewModel(map: GameManager.shared.map)
    @State private var selectedVillage: Village?
    @State private var selectedUnits: [Unit]?
    @State private var refreshTrigger = false

    var body: some View {
        VStack(alignment: .center, spacing: 2.0) {
            ForEach((0...self.viewModel.getMapHeight()), id: \.self) { y in
                HStack(alignment: .center, spacing: 2.0) {
                    ForEach((0...self.viewModel.getMapWidth()), id: \.self) { x in
                        MapTile(x: x, y: y, viewModel: viewModel, onTap: {
                            handleTileTap(x: x, y: y)
                        })
                    }
                }
            }
        }
        .sheet(item: Binding(
            get: { selectedVillage.map { VillageWrapper(village: $0) } },
            set: { selectedVillage = $0?.village }
        )) { wrapper in
            VillageDetailView(
                village: getCurrentVillage(wrapper.village),
                isPresented: Binding(
                    get: { selectedVillage != nil },
                    set: { if !$0 {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedVillage = nil
                        }
                    } }
                ),
                onUpdate: {
                    // Refresh the village when updated
                    if let coords = selectedVillage?.coordinates {
                        selectedVillage = viewModel.getVillageAt(x: Int(coords.x), y: Int(coords.y))
                    }
                }
            )
            .frame(minWidth: 600, minHeight: 700)
            .transition(.scale.combined(with: .opacity))
        }
        .sheet(item: Binding(
            get: { selectedUnits.map { UnitsWrapper(units: $0) } },
            set: { selectedUnits = $0?.units }
        )) { wrapper in
            UnitDetailView(
                units: wrapper.units,
                isPresented: Binding(
                    get: { selectedUnits != nil },
                    set: { if !$0 {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedUnits = nil
                        }
                    } }
                )
            )
            .frame(minWidth: 500, minHeight: 600)
            .transition(.scale.combined(with: .opacity))
        }
    }

    func handleTileTap(x: Int, y: Int) {
        print("🔍 Tile tapped at (\(x), \(y))")

        // Check for village first
        if let village = viewModel.getVillageAt(x: x, y: y) {
            print("🏘️ Found village: \(village.name)")

            // Check if player can access this village
            if let playerNationality = GameManager.shared.playerNationality {
                if village.nationality.name != playerNationality.name {
                    print("❌ Cannot access village of different nationality")
                    return
                }
            }

            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedVillage = village
                print("✅ selectedVillage set to: \(selectedVillage?.name ?? "nil")")
            }
            return
        }

        // Check for units
        let units = viewModel.getUnitsAt(x: x, y: y)
        if !units.isEmpty {
            print("⚔️ Found \(units.count) units")
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedUnits = units
            }
            return
        }

        print("❌ Nothing found at this tile")
    }

    func getCurrentVillage(_ fallback: Village) -> Village {
        // Get the latest version from the map
        if let updated = viewModel.getVillageAt(x: Int(fallback.coordinates.x), y: Int(fallback.coordinates.y)) {
            return updated
        }
        return fallback
    }
}

struct VillageWrapper: Identifiable {
    let id = UUID()
    let village: Village
}

struct UnitsWrapper: Identifiable {
    let id = UUID()
    let units: [Unit]
}

extension MapViewModel {
    func getUnitsAt(x: Int, y: Int) -> [Unit] {
        return map.getUnitsAt(x: x, y: y)
    }
}

struct MapTile: View {
    let x: Int
    let y: Int
    @ObservedObject var viewModel: MapViewModel
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(viewModel.getColorAt(x: x, y: y))
                .frame(width: 20.0, height: 20.0)

            // Village flag or unit icon
            Text(viewModel.getTextAt(x, y))
                .font(.system(size: 12))
                .scaleEffect(isPressed ? 1.2 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isPressed)

            // Strategic resource indicator
            if viewModel.hasStrategicResource(x: x, y: y) {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 6, height: 6)
                    .offset(x: 6, y: -6)
                    .shadow(color: .yellow.opacity(0.5), radius: 2)
            }

            // Unit count indicator
            let unitCount = viewModel.getUnitCount(x: x, y: y)
            if unitCount > 0 {
                Text("\(unitCount)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .padding(2)
                    .background(Circle().fill(Color.red))
                    .offset(x: -6, y: 6)
                    .shadow(color: .red.opacity(0.5), radius: 2)
            }
        }
        .cornerRadius(3.0)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .shadow(color: isPressed ? Color.blue.opacity(0.3) : Color.clear, radius: 4)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: 50) {
            print("✨ Tap completed at (\(x), \(y))")
            onTap()
        } onPressingChanged: { pressing in
            isPressed = pressing
            if pressing {
                print("👇 Press started at (\(x), \(y))")
            }
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}

class MapViewModel: ObservableObject {
    @Published var map: Map

    init(map: Map) {
        self.map = map
        // Subscribe to GameManager changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("MapUpdated"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    func getMapHeight() -> Int {
        return Int(map.size.height) - 1
    }

    func getMapWidth() -> Int {
        return Int(map.size.width) - 1
    }

    func getColorAt(x: Int, y: Int) -> Color {
        // Check for village first
        if let village = map.getVillageAt(x: x, y: y) {
            return village.mapColor
        }

        // Otherwise show terrain color
        if let virtualMap = map as? VirtualMap,
           let tile = virtualMap.getTile(at: CGPoint(x: x, y: y)) {
            return tile.terrain.color
        }

        return Color(red: 0.8, green: 0.8, blue: 0.8) // Default gray
    }

    func getTextAt(_ x: Int, _ y: Int) -> String {
        if let village = map.getVillageAt(x: x, y: y) {
            return village.nationality.flag
        } else {
            return ""
        }
    }

    func getVillageAt(x: Int, y: Int) -> Village? {
        return map.getVillageAt(x: x, y: y)
    }

    func hasStrategicResource(x: Int, y: Int) -> Bool {
        if let virtualMap = map as? VirtualMap,
           let tile = virtualMap.getTile(at: CGPoint(x: x, y: y)) {
            return tile.strategicResource != nil
        }
        return false
    }

    func getUnitCount(x: Int, y: Int) -> Int {
        return map.getUnitsAt(x: x, y: y).count
    }
}
