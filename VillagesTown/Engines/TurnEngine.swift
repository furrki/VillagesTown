//
//  TurnEngine.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 12.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import Foundation

class TurnEngine {
    static func doBuildingProduction(game: inout GameManager) {
        for index in game.map.villages.indices {
            BuildingProductionEngine.consumeAndProduceAll(in: &game.map.villages[index])
        }
    }
    
    static func doTurn(game: inout GameManager) {
        doBuildingProduction(game: &game)
    }
}
