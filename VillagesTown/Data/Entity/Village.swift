//
//  Village.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 10.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import CoreGraphics

class Village {

    // MARK: - Properties
    let coordinates: CGPoint
    var level: Level = .village
    private var resourceManager: ResourceManager = ResourceManager()
    private(set) var money: Double = Constants.villageStartCash
    
    init(coordinates: CGPoint) {
        self.coordinates = coordinates
    }
    
    // MARK: - Methods
    
    // MARK: - Private Methods
    
}
