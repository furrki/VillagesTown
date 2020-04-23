//
//  Building.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 11.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import Foundation

struct Building {
    enum BuildingType {
        case production
    }
    
    var type: BuildingType
    var name: String
    var baseCost: Double
    var level: Int = 1
    var resourcesProduction: [Resource: Int] = [:]
    var resourcesConsumption: [Resource: Int] = [:]
    
    static let all: [Building] = [
        Building(type: .production, name: "Iron Mine", baseCost: 5.0, resourcesProduction: [.iron: 5], resourcesConsumption: [:])
    ]
}
