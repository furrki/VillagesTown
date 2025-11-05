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
    @State private var showVillageDetail = false

    var body: some View {
        VStack(alignment: .center, spacing: 2.0) {
            ForEach((0...self.viewModel.getMapHeight()), id: \.self) { y in
                HStack(alignment: .center, spacing: 2.0) {
                    ForEach((0...self.viewModel.getMapWidth()), id: \.self) { x in
                        MapTile(x: x, y: y, viewModel: viewModel)
                            .onTapGesture {
                                handleTileTap(x: x, y: y)
                            }
                    }
                }
            }
        }
        .sheet(isPresented: $showVillageDetail) {
            if let village = selectedVillage {
                VillageDetailView(village: village, isPresented: $showVillageDetail)
            }
        }
    }

    func handleTileTap(x: Int, y: Int) {
        if let village = viewModel.getVillageAt(x: x, y: y) {
            selectedVillage = village
            showVillageDetail = true
        }
    }
}

struct MapTile: View {
    let x: Int
    let y: Int
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        ZStack {
            Rectangle()
                .fill(viewModel.getColorAt(x: x, y: y))
                .frame(width: 20.0, height: 20.0)

            Text(viewModel.getTextAt(x, y))
                .font(.system(size: 12))
        }
        .cornerRadius(3.0)
        .overlay(
            viewModel.hasStrategicResource(x: x, y: y) ?
            Circle()
                .fill(Color.yellow)
                .frame(width: 6, height: 6)
                .offset(x: 6, y: -6)
            : nil
        )
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
}
