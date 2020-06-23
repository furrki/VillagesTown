//
//  BuildingProductionEngine.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 12.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import Foundation

class BuildingProductionEngine {
    static func consumeAndProduceAll(in village: inout Village) {
        
        for building in village.buildings {
            if village.substract(building.resourcesConsumption) {
                village.add(building.resourcesProduction)
            } else {
                print("In \(village.name), \(building.name) couldn't work.")
            }
        }
    }
}
