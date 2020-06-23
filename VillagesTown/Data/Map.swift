//
//  Map.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 10.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import CoreGraphics

protocol Map {
    var size: CGSize { get }
    var villages: [Village] { get set }
}

class VirtualMap: Map {
    let size: CGSize
    var villages: [Village] = []
    
    
    init(size: CGSize, villages: [Village] = []) {
        self.size = size
        self.villages = villages
    }
}

extension Map {
    var entities: [Entity] {
        return [villages].flatMap { $0 }
    }
    
    func getEntityAt(x: Int, y: Int) -> Entity? {
        return entities.first(where: { $0.coordinates.x == CGFloat(x) && $0.coordinates.y == CGFloat(y) })
    }
}
