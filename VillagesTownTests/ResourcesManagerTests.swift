//
//  ResourcesManagerTests.swift
//  VillagesTownTests
//
//  Created by Furkan Kaynar on 12.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import XCTest
@testable import VillagesTown

class ResourcesHolderTests: XCTestCase {

    var village: Village = Village(name: "Age of Empires", coordinates: CGPoint.zero)
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAddSubstract() {
        XCTAssertEqual(village.resources, [:])
        village.add(.iron, amount: -5)
        XCTAssertEqual(village.resources, [:])
        village.add(.iron, amount: 50)
        XCTAssertEqual(village.resources, [.iron: 50])
        XCTAssertTrue(village.substract(.iron, amount: 40))
        XCTAssertEqual(village.resources, [.iron: 10])
        XCTAssertFalse(village.substract(.iron, amount: 50))
        XCTAssertEqual(village.resources, [.iron: 10])
        XCTAssertFalse(village.substract([.iron: 60]))
    }
    
    func testAddQueue() {
        village.add([.iron: 20])
        XCTAssertEqual(village.resources, [.iron: 20])
    }
    
    func testIsSufficent() {
        village.add(.iron, amount: 50)
        XCTAssertTrue(village.isSufficent(.iron, amount: 50))
        XCTAssertFalse(village.isSufficent(.iron, amount: 51))
        village.add([.iron: 50])
        XCTAssertTrue(village.isSufficent([.iron: 100]))
        XCTAssertFalse(village.isSufficent([.iron: 101]))
    }
}
