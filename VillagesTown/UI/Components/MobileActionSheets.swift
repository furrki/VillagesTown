//
//  MobileActionSheets.swift
//  VillagesTown
//
//  Action sheets for mobile - Build, Recruit, and Village Info
//

import SwiftUI

// MARK: - Village Detail Modal

struct VillageDetailModal: View {
    let village: Village
    @Environment(\.dismiss) var dismiss

    var armies: [Army] {
        GameManager.shared.getArmiesAt(villageID: village.id)
    }

    var isPlayerVillage: Bool { village.owner == "player" }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    villageHeader

                    if isPlayerVillage {
                        // Stats
                        statsSection

                        // Buildings
                        buildingsSection

                        // Armies
                        if !armies.isEmpty {
                            armiesSection
                        }

                        // Production
                        productionSection
                    } else {
                        enemyVillageInfo
                    }
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle(village.name)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    var villageHeader: some View {
        HStack(spacing: 16) {
            Text(village.nationality.flag)
                .font(.system(size: 48))

            VStack(alignment: .leading, spacing: 4) {
                Text(village.nationality.name)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.6))

                HStack {
                    Label("Level \(village.level.rawValue)", systemImage: "star.fill")
                        .foregroundColor(.yellow)
                    Label("\(village.maxBuildings) slots", systemImage: "building.2")
                        .foregroundColor(.white.opacity(0.6))
                }
                .font(.caption)
            }

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Statistics")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatBox(icon: "person.3.fill", value: "\(village.population)", label: "Population", color: .blue)
                StatBox(icon: "shield.fill", value: "\(village.garrisonStrength)", label: "Garrison", color: .green)
                StatBox(icon: "building.2.fill", value: "\(village.buildings.count)/\(village.maxBuildings)", label: "Buildings", color: .orange)
            }
        }
    }

    var buildingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Buildings")

            if village.buildings.isEmpty {
                Text("No buildings constructed")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(village.buildings, id: \.id) { building in
                        HStack {
                            Text(buildingIcon(for: building))
                                .font(.title3)
                            VStack(alignment: .leading) {
                                Text(building.name)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                Text("Lvl \(building.level)")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                    }
                }
            }
        }
    }

    func buildingIcon(for building: Building) -> String {
        switch building.name {
        case "Farm": return "🌾"
        case "Lumber Mill": return "🪵"
        case "Iron Mine": return "⛏️"
        case "Market": return "🏪"
        case "Barracks": return "⚔️"
        case "Archery Range": return "🏹"
        case "Stables": return "🐴"
        case "Fortress": return "🏰"
        case "Granary": return "🏛️"
        case "Temple": return "⛪"
        case "Library": return "📚"
        default: return "🏠"
        }
    }

    var armiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Armies")

            ForEach(armies, id: \.id) { army in
                HStack {
                    Text(army.emoji)
                        .font(.title2)

                    VStack(alignment: .leading) {
                        Text(army.name)
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Text("\(army.unitCount) units • \(army.strength) STR")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    if army.isMarching {
                        Text("\(army.turnsUntilArrival) turns")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
        }
    }

    var productionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Production per Turn")

            HStack(spacing: 16) {
                ForEach(Resource.getAll(), id: \.self) { resource in
                    let production = calculateProduction(for: resource)
                    VStack {
                        Text(resource.emoji)
                            .font(.title3)
                        Text("+\(production)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(production > 0 ? .green : .white.opacity(0.3))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
    }

    var enemyVillageInfo: some View {
        VStack(spacing: 16) {
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))

            Text("Enemy Territory")
                .font(.headline)
                .foregroundColor(.white.opacity(0.6))

            Text("Detailed information is hidden for enemy villages.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)

            HStack {
                Label("\(village.garrisonStrength)", systemImage: "shield.fill")
                    .foregroundColor(.red)
            }
            .font(.headline)
            .padding()
            .background(Color.red.opacity(0.2))
            .cornerRadius(12)
        }
        .padding(.top, 40)
    }

    func calculateProduction(for resource: Resource) -> Int {
        var production = 0
        for building in village.buildings {
            if let prod = building.resourcesProduction[resource] {
                production += prod * building.level
            }
        }
        return production
    }
}

// MARK: - Build Sheet

struct BuildSheet: View {
    let village: Village
    let onBuild: (Building) -> Void
    @Environment(\.dismiss) var dismiss
    @ObservedObject var gameManager = GameManager.shared

    let buildingEngine = BuildingConstructionEngine()

    var currentVillage: Village {
        gameManager.map.villages.first { $0.id == village.id } ?? village
    }

    var resources: [Resource: Int] {
        gameManager.getGlobalResources(playerID: "player")
    }

    var availableBuildings: [Building] {
        Building.all.filter { building in
            !currentVillage.buildings.contains { $0.name == building.name }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Your Buildings section (with upgrades)
                    if !currentVillage.buildings.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("YOUR BUILDINGS")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white.opacity(0.4))
                                Spacer()
                                Text("\(currentVillage.buildings.count)/\(currentVillage.maxBuildings)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal)

                            ForEach(currentVillage.buildings, id: \.id) { building in
                                BuildingUpgradeCard(
                                    building: building,
                                    village: currentVillage,
                                    resources: resources,
                                    onUpgrade: { upgradeBuilding(building) }
                                )
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Build New section
                    if !availableBuildings.isEmpty && currentVillage.buildings.count < currentVillage.maxBuildings {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("BUILD NEW")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.horizontal)

                            ForEach(availableBuildings, id: \.id) { building in
                                MobileBuildingCard(
                                    building: building,
                                    village: currentVillage,
                                    canBuild: canBuild(building),
                                    onBuild: { onBuild(building) }
                                )
                            }
                            .padding(.horizontal)
                        }
                    } else if currentVillage.buildings.count >= currentVillage.maxBuildings {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Village full - upgrade village level for more slots")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Buildings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    func canBuild(_ building: Building) -> Bool {
        guard currentVillage.buildings.count < currentVillage.maxBuildings else { return false }
        for (resource, cost) in building.baseCost {
            if (resources[resource] ?? 0) < cost {
                return false
            }
        }
        return true
    }

    func upgradeBuilding(_ building: Building) {
        var mutableVillage = currentVillage
        if buildingEngine.upgradeBuilding(buildingID: building.id, in: &mutableVillage) {
            gameManager.updateVillage(mutableVillage)
        }
    }
}

struct BuildingUpgradeCard: View {
    let building: Building
    let village: Village
    let resources: [Resource: Int]
    let onUpgrade: () -> Void

    let buildingEngine = BuildingConstructionEngine()

    var upgradeInfo: (can: Bool, cost: [Resource: Int], reason: String) {
        buildingEngine.canUpgradeBuilding(building, in: village)
    }

    var icon: String {
        switch building.name {
        case "Farm": return "🌾"
        case "Lumber Mill": return "🪵"
        case "Iron Mine": return "⛏️"
        case "Market": return "🏪"
        case "Barracks": return "⚔️"
        case "Archery Range": return "🏹"
        case "Stables": return "🐴"
        case "Fortress": return "🏰"
        case "Granary": return "🏛️"
        case "Temple": return "⛪"
        case "Library": return "📚"
        default: return "🏠"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Text(icon)
                .font(.system(size: 28))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(building.name)
                        .font(.headline)
                        .foregroundColor(.white)

                    // Level badge
                    Text("Lv.\(building.level)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.yellow))
                }

                if building.level >= 5 {
                    Text("Max level reached")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    // Upgrade cost
                    HStack(spacing: 8) {
                        ForEach(Array(upgradeInfo.cost.keys), id: \.self) { resource in
                            let cost = upgradeInfo.cost[resource] ?? 0
                            let have = resources[resource] ?? 0
                            HStack(spacing: 2) {
                                Text(resource.emoji)
                                    .font(.system(size: 11))
                                Text("\(cost)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(have >= cost ? .yellow : .red)
                            }
                        }
                    }
                }
            }

            Spacer()

            // Upgrade button
            if building.level < 5 {
                Button(action: {
                    LayoutConstants.impactFeedback()
                    onUpgrade()
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24))
                        Text("Lv.\(building.level + 1)")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(upgradeInfo.can ? .green : .gray)
                }
                .disabled(!upgradeInfo.can)
            } else {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(building.level >= 5 ? Color.green.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct MobileBuildingCard: View {
    let building: Building
    let village: Village
    let canBuild: Bool
    let onBuild: () -> Void

    var icon: String {
        switch building.name {
        case "Farm": return "🌾"
        case "Lumber Mill": return "🪵"
        case "Iron Mine": return "⛏️"
        case "Market": return "🏪"
        case "Barracks": return "⚔️"
        case "Archery Range": return "🏹"
        case "Stables": return "🐴"
        case "Fortress": return "🏰"
        case "Granary": return "🏛️"
        case "Temple": return "⛪"
        case "Library": return "📚"
        default: return "🏠"
        }
    }

    var body: some View {
        Button(action: {
            LayoutConstants.impactFeedback()
            onBuild()
        }) {
            HStack(spacing: 16) {
                Text(icon)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(building.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)

                    // Cost
                    HStack(spacing: 8) {
                        ForEach(Array(building.baseCost.keys), id: \.self) { resource in
                            HStack(spacing: 2) {
                                Text(resource.emoji)
                                    .font(.caption)
                                Text("\(building.baseCost[resource] ?? 0)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(canBuild ? .green : .gray)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(canBuild ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!canBuild)
        .opacity(canBuild ? 1 : 0.5)
    }
}

// MARK: - Recruit Sheet

struct RecruitSheet: View {
    let village: Village
    let onRecruit: (Unit.UnitType, Int) -> Void
    @Environment(\.dismiss) var dismiss
    @ObservedObject var gameManager = GameManager.shared

    @State private var selectedType: Unit.UnitType = .militia
    @State private var quantity: Int = 1

    let unitTypes: [Unit.UnitType] = [.militia, .spearman, .swordsman, .archer, .crossbowman, .lightCavalry, .knight]

    var currentVillage: Village {
        gameManager.map.villages.first { $0.id == village.id } ?? village
    }

    var resources: [Resource: Int] {
        gameManager.getGlobalResources(playerID: "player")
    }

    // Get required building for unit type
    func requiredBuilding(for type: Unit.UnitType) -> String {
        switch type.category {
        case "Infantry": return "Barracks"
        case "Ranged": return "Archery Range"
        case "Cavalry": return "Stables"
        default: return "Barracks"
        }
    }

    func hasRequiredBuilding(for type: Unit.UnitType) -> Bool {
        let required = requiredBuilding(for: type)
        return currentVillage.buildings.contains { $0.name == required }
    }

    func canAffordUnit(_ type: Unit.UnitType, qty: Int) -> Bool {
        let stats = Unit.getStats(for: type)
        for (resource, cost) in stats.cost {
            if (resources[resource] ?? 0) < cost * qty {
                return false
            }
        }
        return true
    }

    var canRecruit: Bool {
        hasRequiredBuilding(for: selectedType) && canAffordUnit(selectedType, qty: quantity)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Resource display
                    resourceBar

                    // Unit selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SELECT UNIT")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(unitTypes, id: \.self) { type in
                                UnitTypeCard(
                                    type: type,
                                    village: currentVillage,
                                    resources: resources,
                                    isSelected: selectedType == type,
                                    onSelect: {
                                        if hasRequiredBuilding(for: type) {
                                            selectedType = type
                                        }
                                    }
                                )
                            }
                        }
                    }

                    // Quantity selector
                    VStack(spacing: 10) {
                        Text("QUANTITY")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.4))

                        HStack(spacing: 16) {
                            ForEach([1, 3, 5, 10], id: \.self) { num in
                                Button(action: { quantity = num }) {
                                    Text("\(num)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(quantity == num ? .black : .white)
                                        .frame(width: 48, height: 48)
                                        .background(
                                            Circle()
                                                .fill(quantity == num ? Color.green : Color.white.opacity(0.1))
                                        )
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }

                    // Cost summary
                    costSummary

                    // Recruit button
                    Button(action: {
                        LayoutConstants.impactFeedback(style: .medium)
                        onRecruit(selectedType, quantity)
                    }) {
                        HStack {
                            Image(systemName: "person.3.fill")
                            Text("Recruit \(quantity) \(selectedType.rawValue)")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canRecruit ? Color.green : Color.gray)
                        .cornerRadius(14)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(!canRecruit)
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Recruit")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    var resourceBar: some View {
        HStack(spacing: 12) {
            ForEach([Resource.gold, Resource.food, Resource.iron, Resource.wood], id: \.self) { resource in
                HStack(spacing: 4) {
                    Text(resource.emoji)
                        .font(.system(size: 14))
                    Text("\(resources[resource] ?? 0)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08))
        .cornerRadius(10)
    }

    var costSummary: some View {
        let stats = Unit.getStats(for: selectedType)
        let totalCost = stats.cost.mapValues { $0 * quantity }

        return VStack(spacing: 8) {
            HStack {
                Text("Total Cost")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                HStack(spacing: 10) {
                    ForEach(Array(totalCost.keys), id: \.self) { resource in
                        let cost = totalCost[resource] ?? 0
                        let have = resources[resource] ?? 0
                        HStack(spacing: 3) {
                            Text(resource.emoji)
                                .font(.system(size: 13))
                            Text("\(cost)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(have >= cost ? .green : .red)
                        }
                    }
                }
            }

            if !hasRequiredBuilding(for: selectedType) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Requires \(requiredBuilding(for: selectedType))")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct UnitTypeCard: View {
    let type: Unit.UnitType
    let village: Village
    let resources: [Resource: Int]
    let isSelected: Bool
    let onSelect: () -> Void

    var requiredBuilding: String {
        switch type.category {
        case "Infantry": return "Barracks"
        case "Ranged": return "Archery Range"
        case "Cavalry": return "Stables"
        default: return "Barracks"
        }
    }

    var hasBuilding: Bool {
        village.buildings.contains { $0.name == requiredBuilding }
    }

    var stats: (name: String, attack: Int, defense: Int, hp: Int, movement: Int, cost: [Resource: Int], upkeep: [Resource: Int]) {
        Unit.getStats(for: type)
    }

    var canAfford: Bool {
        for (resource, cost) in stats.cost {
            if (resources[resource] ?? 0) < cost {
                return false
            }
        }
        return true
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                // Lock overlay if no building
                ZStack {
                    Text(type.emoji)
                        .font(.system(size: 28))
                        .opacity(hasBuilding ? 1 : 0.3)

                    if !hasBuilding {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                            .offset(x: 14, y: -10)
                    }
                }

                Text(type.rawValue)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(hasBuilding ? .white : .white.opacity(0.4))

                // Stats
                HStack(spacing: 6) {
                    HStack(spacing: 2) {
                        Image(systemName: "burst.fill")
                            .font(.system(size: 8))
                        Text("\(stats.attack)")
                    }
                    .foregroundColor(.red.opacity(0.8))

                    HStack(spacing: 2) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 8))
                        Text("\(stats.defense)")
                    }
                    .foregroundColor(.blue.opacity(0.8))
                }
                .font(.system(size: 9, weight: .semibold))

                // Cost
                HStack(spacing: 4) {
                    ForEach(Array(stats.cost.keys), id: \.self) { resource in
                        HStack(spacing: 1) {
                            Text(resource.emoji)
                                .font(.system(size: 9))
                            Text("\(stats.cost[resource] ?? 0)")
                                .font(.system(size: 9, weight: .bold))
                        }
                    }
                }
                .foregroundColor(.yellow.opacity(hasBuilding ? 1 : 0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected && hasBuilding ? Color.green.opacity(0.2) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected && hasBuilding ? Color.green : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!hasBuilding)
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}
