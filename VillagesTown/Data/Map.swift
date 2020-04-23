//
//  Map.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 10.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import CoreGraphics

protocol Map {
    var villages: [Village] { get set }
    var entities: [Entity] { get set }
}

class VirtualMap: Map {
    let size: CGSize
    var villages: [Village] = []
    var entities: [Entity] = []
    
    init(size: CGSize, villages: [Village] = []) {
        self.size = size
        self.villages = villages
    }
}
