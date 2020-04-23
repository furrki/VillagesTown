//
//  BuildingProductionEngineTests.swift
//  VillagesTownTests
//
//  Created by Furkan Kaynar on 23.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import XCTest
@testable import VillagesTown

class BuildingProductionEngineTests: XCTestCase {
    func testProduction() {
        var village: Village = Village(name: "Argithan", coordinates: CGPoint(x: 10, y: 10))
        village.resources[.iron] = 100
        village.resources[.wood] = 50
        village.buildings = [
            Building(type: .production, name: "", baseCost: 2.0, resourcesProduction: [.iron: 10], resourcesConsumption: [.wood: 20])
        ]
        
        XCTAssertEqual(village.resources[.iron], 100)
        XCTAssertEqual(village.resources[.wood], 50)
        BuildingProductionEngine.consumeAndProduceAll(in: &village)
        XCTAssertEqual(village.resources[.iron], 110)
        XCTAssertEqual(village.resources[.wood], 30)
    }
}
