//
//  GameManager.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 10.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import Foundation

class GameManager {
    static let shared: GameManager = GameManager()
    // MARK: - Properties
    var map: Map
    let turnEngine: TurnEngine = TurnEngine()
    
    // MARK: - Initializers
    init() {
        let initialVillages: [Village] = [
            Village(name: "Argithan", nationality: Nationality.getAll()[0], coordinates: CGPoint(x: 10, y: 10)),
            Village(name: "Zafer", nationality: Nationality.getAll()[1], coordinates: CGPoint(x: 10, y: 15)),
            Village(name: "Tunceli", nationality: Nationality.getAll()[2], coordinates: CGPoint(x: 5, y: 10)),
        ]
        
        map = VirtualMap(size: CGSize(width: 20.0, height: 20.0), villages: initialVillages)
    }
    
    func initializeGame() {
        
    }
    
    // MARK: - Methods
}
