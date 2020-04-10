//
//  GameManager.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 10.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import Foundation

class GameManager {
    // MARK: - Properties
    var map: Map
    
    // MARK: - Initializers
    init() {
        let initialVillages: [Village] = [
            Village(name: "Argithan", coordinates: CGPoint(x: 10, y: 10))
        ]
        
        map = VirtualMap(size: CGSize(width: 20.0, height: 20.0), villages: initialVillages)
    }
    
    func initializeGame() {
        
    }
    
    // MARK: - Methods
}
