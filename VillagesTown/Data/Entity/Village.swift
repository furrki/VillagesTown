//
//  Village.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 10.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import SwiftUI

struct Village: Entity, ResourceHolder, TreasuryHolder {
    // MARK: - Properties
    let name: String
    var mapColor: Color = .red
    let nationality: Nationality
    let isMovable: Bool = false
    var coordinates: CGPoint
    var level: Level = .village
    var buildings: [Building] = []
    var resources: [Resource : Int] = [:]
    var money: Double = Constants.villageStartCash
    private(set) var population: Int = Constants.villageStartPopulation
    
    init(name: String, nationality: Nationality, coordinates: CGPoint) {
        self.name = name
        self.nationality = nationality
        self.coordinates = coordinates
        self.buildings = Building.all
    }
    
    // MARK: - Methods
    
}
