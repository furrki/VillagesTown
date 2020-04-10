//
//  ResourceManager.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 10.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import Foundation

class ResourceManager {
    private(set) var resources: [Resource: Int] = [:]
    
    func add(_ resource: Resource, amount: Int) {
        if amount > 0 {
            resources[resource] = amount + (resources[resource] ?? 0)
        }
    }
    
    func substract(_ resource: Resource, amount: Int) {
        if amount > 0 && (resources[resource] ?? 0) >= amount {
            resources[resource] = (resources[resource] ?? 0) - amount
        }
    }
    
    func isSufficent(_ resource: Resource, amount: Int) -> Bool {
        return amount > 0 && (resources[resource] ?? 0) >= amount
    }
    
    func get(_ resource: Resource) -> Int {
        return resources[resource] ?? 0
    }
}
