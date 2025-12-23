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
    @State private var selectedUnitForMovement: Unit? // For player movement
    @State private var validMovementTiles: Set<String> = [] // "x,y" format
    @State private var showAttackConfirmation = false
    @State private var attackTarget: Village?
    @State private var attackResult: String = ""
    @State private var showAttackResult = false
    @State private var refreshTrigger = false

    var body: some View {
        VStack(alignment: .center, spacing: 2.0) {
            ForEach((0...self.viewModel.getMapHeight()), id: \.self) { y in
                HStack(alignment: .center, spacing: 2.0) {
                    ForEach((0...self.viewModel.getMapWidth()), id: \.self) { x in
                        MapTile(
                            x: x,
                            y: y,
                            viewModel: viewModel,
                            isSelected: isSelectedTile(x: x, y: y),
                            isValidMove: validMovementTiles.contains("\(x),\(y)"),
                            onTap: {
                                handleTileTap(x: x, y: y)
                            }
                        )
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
        .alert("Attack Village?", isPresented: $showAttackConfirmation) {
            Button("Cancel", role: .cancel) {
                showAttackConfirmation = false
            }
            Button("Attack", role: .destructive) {
                executeAttack()
            }
        } message: {
            if let target = attackTarget {
                Text("Attack \(target.name)? Your units will engage the defenders.")
            }
        }
        .alert("Battle Result", isPresented: $showAttackResult) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(attackResult)
        }
    }

    func handleTileTap(x: Int, y: Int) {
        print("🔍 Tile tapped at (\(x), \(y))")

        // If a unit is selected for movement, try to move it
        if let unit = selectedUnitForMovement {
            // Safety check: only allow player units
            guard unit.owner == "player" else {
                print("❌ Cannot move enemy unit!")
                selectedUnitForMovement = nil
                validMovementTiles.removeAll()
                return
            }

            let destination = CGPoint(x: x, y: y)

            // Check if this is a valid movement tile
            if validMovementTiles.contains("\(x),\(y)") {
                var mutableUnit = unit
                var mutableMap = GameManager.shared.map
                let movementEngine = MovementEngine()

                if movementEngine.moveUnit(unit: &mutableUnit, to: destination, map: &mutableMap) {
                    GameManager.shared.map = mutableMap
                    print("✅ Unit moved successfully")

                    // Clear selection
                    selectedUnitForMovement = nil
                    validMovementTiles.removeAll()

                    // Refresh view
                    NotificationCenter.default.post(name: NSNotification.Name("MapUpdated"), object: nil)
                    return
                }
            } else {
                // Tapped somewhere else - deselect unit
                print("❌ Invalid move destination - deselecting unit")
                selectedUnitForMovement = nil
                validMovementTiles.removeAll()
            }
        }

        // Check for village first
        if let village = viewModel.getVillageAt(x: x, y: y) {
            print("🏘️ Found village: \(village.name)")

            // If unit is selected and this is an enemy village, check if attack is possible
            if let selectedUnit = selectedUnitForMovement, village.owner != "player" {
                let unitX = Int(selectedUnit.coordinates.x)
                let unitY = Int(selectedUnit.coordinates.y)
                let distance = max(abs(x - unitX), abs(y - unitY))

                // Check if adjacent (within 1 tile)
                if distance <= 1 {
                    print("⚔️ Enemy village is adjacent - can attack!")
                    attackTarget = village
                    showAttackConfirmation = true
                    return
                } else {
                    print("❌ Enemy village is too far to attack (distance: \(distance))")
                }
            }

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

            // If there are player units, select them for movement directly (no detail view)
            let playerUnits = units.filter { $0.owner == "player" }
            if !playerUnits.isEmpty, let unit = playerUnits.first {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedUnitForMovement = unit
                    calculateValidMovementTiles(for: unit)
                }
                print("✅ Selected unit for movement")
                return
            }

            // If only enemy units, show details (read-only)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedUnits = units
            }
            return
        }

        print("❌ Nothing found at this tile")
    }

    func isSelectedTile(x: Int, y: Int) -> Bool {
        guard let unit = selectedUnitForMovement else { return false }
        return Int(unit.coordinates.x) == x && Int(unit.coordinates.y) == y
    }

    func calculateValidMovementTiles(for unit: Unit) {
        validMovementTiles.removeAll()
        let movementEngine = MovementEngine()

        // Check all tiles within movement range
        let range = unit.movementRemaining
        let unitX = Int(unit.coordinates.x)
        let unitY = Int(unit.coordinates.y)

        for dx in -range...range {
            for dy in -range...range {
                let x = unitX + dx
                let y = unitY + dy

                // Skip current position
                if dx == 0 && dy == 0 { continue }

                let destination = CGPoint(x: x, y: y)
                let check = movementEngine.canMoveTo(unit: unit, destination: destination, map: GameManager.shared.map)

                if check.can {
                    validMovementTiles.insert("\(x),\(y)")
                }
            }
        }

        print("📍 Valid movement tiles: \(validMovementTiles.count)")
    }

    func executeAttack() {
        guard let target = attackTarget,
              let selectedUnit = selectedUnitForMovement else {
            print("❌ No attack target or selected unit")
            return
        }

        print("⚔️ Executing attack on \(target.name)")

        // Get all player units at selected unit's location
        var attackers = GameManager.shared.map.getUnitsAt(point: selectedUnit.coordinates)
            .filter { $0.owner == "player" }

        // Get all defender units at target village
        var defenders = GameManager.shared.map.getUnitsAt(point: target.coordinates)
            .filter { $0.owner == target.owner }

        let combatEngine = CombatEngine()

        // Execute combat
        let result = combatEngine.resolveCombat(
            attackers: &attackers,
            defenders: &defenders,
            location: target.coordinates,
            map: GameManager.shared.map,
            defendingVillage: target
        )

        // Update units on map - combat engine already removed dead units from arrays
        // Just need to update the map's unit list
        for attacker in attackers {
            GameManager.shared.map.updateUnit(attacker)
        }
        for defender in defenders {
            GameManager.shared.map.updateUnit(defender)
        }

        // Check if village was conquered
        if result.attackerWon && defenders.isEmpty {
            // Conquer the village
            var mutableTarget = target
            mutableTarget.owner = "player"
            mutableTarget.population = Int(Double(mutableTarget.population) * 0.7) // 30% population loss
            mutableTarget.happiness -= 30 // Happiness penalty
            GameManager.shared.updateVillage(mutableTarget)

            attackResult = "🎉 Victory! \(target.name) conquered!\n\nLost: \(result.attackerCasualties) units\nKilled: \(result.defenderCasualties) enemies"
        } else if result.attackerWon {
            attackResult = "✅ Victory! Enemy forces defeated!\n\nLost: \(result.attackerCasualties) units\nKilled: \(result.defenderCasualties) enemies"
        } else {
            attackResult = "❌ Defeat! Your forces were repelled.\n\nLost: \(result.attackerCasualties) units\nKilled: \(result.defenderCasualties) enemies"
        }

        // Clear selection
        selectedUnitForMovement = nil
        validMovementTiles.removeAll()
        attackTarget = nil

        // Show result
        showAttackResult = true

        // Refresh map
        NotificationCenter.default.post(name: NSNotification.Name("MapUpdated"), object: nil)
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
    let isSelected: Bool
    let isValidMove: Bool
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(viewModel.getColorAt(x: x, y: y))
                .frame(width: 20.0, height: 20.0)

            // Selected unit ring
            if isSelected {
                Rectangle()
                    .strokeBorder(Color.blue, lineWidth: 2)
                    .frame(width: 20.0, height: 20.0)
                    .shadow(color: .blue.opacity(0.6), radius: 3)
            }

            // Valid movement indicator
            if isValidMove {
                Rectangle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: 20.0, height: 20.0)
            }

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
            // Color by ownership
            if village.owner == "player" {
                return Color.green.opacity(0.6)
            } else {
                return Color.red.opacity(0.6)
            }
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
