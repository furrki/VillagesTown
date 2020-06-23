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
    
    var body: some View {
        VStack(alignment: .center, spacing: 5.0) {
            ForEach((0...self.viewModel.getMapHeight()), id: \.self) { y in
                HStack(alignment: .center, spacing: 5.0) {
                    ForEach((0...self.viewModel.getMapWidth()), id: \.self) { x in
    
                        
                        VStack(alignment: .center, spacing: 5.0) {
                            Text(self.viewModel.getTextAt(x, y))
                        }
                        .frame(width: 20.0, height: 20.0, alignment: .center)
                        .background(self.viewModel
                        .getColorAt(x: x, y: y))
                        .cornerRadius(5.0)
                        
                    }
                }
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
    }
    
    func getMapHeight() -> Int {
        return Int(map.size.height) - 1
    }
    
    func getMapWidth() -> Int {
        return Int(map.size.width) - 1
    }
    
    func getColorAt(x: Int, y: Int) -> Color {
        if let entity: Entity = map.getEntityAt(x: x, y: y) {
            return entity.mapColor
        } else {
            return .gray
        }
    }
    func getTextAt(_ x: Int, _ y: Int) -> String {
        if let village: Village = map.getEntityAt(x: x, y: y) as? Village {
            return village.nationality.flag
        } else {
            return ""
        }
    }
}
