//
//  TreasuryHolderTests.swift
//  VillagesTownTests
//
//  Created by Furkan Kaynar on 23.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import XCTest
@testable import VillagesTown

class TreasuryHolderTests: XCTestCase {
    var village: Village = Village(name: "Age of Empires", nationality: Nationality.getAll()[0], coordinates: CGPoint.zero)

    func testAddAndSubstract() {
        village.money = 500
        village.add(money: 200)
        XCTAssertEqual(village.money, 700)
        village.add(money: -20)
        XCTAssertEqual(village.money, 700)
        village.substract(money: 400)
        XCTAssertEqual(village.money, 300)
        village.substract(money: 600)
        XCTAssertEqual(village.money, 300)
    }
}
