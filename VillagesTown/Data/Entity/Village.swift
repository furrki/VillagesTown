//
//  Village.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 10.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import CoreGraphics

struct Village: ResourceHolder {
    // MARK: - Properties
    let name: String
    let coordinates: CGPoint
    var level: Level = .village
    var buildings: [Building] = []
    var resources: [Resource : Int] = [:]
    private(set) var money: Double = Constants.villageStartCash
    private(set) var population: Int = Constants.villageStartPopulation
    
    init(name: String, coordinates: CGPoint) {
        self.name = name
        self.coordinates = coordinates
        self.buildings = Building.all
    }
    
    // MARK: - Methods
    
    // MARK: - Private Methods
    
}
