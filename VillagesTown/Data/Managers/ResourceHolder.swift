//
//  ResourceHolder.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 23.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import Foundation

protocol ResourceHolder {
    var resources: [Resource: Int] { get set }
}

extension ResourceHolder {
    mutating func add(_ resource: Resource, amount: Int) {
        if amount > 0 {
            resources[resource] = amount + (resources[resource] ?? 0)
        }
    }
    
    mutating func add(_ resourcesToAdd: [Resource: Int]) {
        resourcesToAdd.forEach { (res, amount) in
            if amount > 0 {
                self.resources[res] = amount + (resources[res] ?? 0)
            }
        }
    }
    
    mutating func substract(_ resource: Resource, amount: Int) -> Bool {
        if isSufficent(resource, amount: amount) {
            if amount > 0 && (resources[resource] ?? 0) >= amount {
                resources[resource] = (resources[resource] ?? 0) - amount
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    mutating func substract(_ resourcesToSubstract: [Resource: Int]) -> Bool {
        if !isSufficent(resourcesToSubstract) {
            return false
        } else {
            for (res, amount) in resourcesToSubstract {
                self.resources[res] = amount - (resources[res] ?? 0)
            }
            return true
        }
    }
    
    func isSufficent(_ resource: Resource, amount: Int) -> Bool {
        return amount > 0 && (resources[resource] ?? 0) >= amount
    }
    
    func isSufficent(_ resourcesToSubstract: [Resource: Int]) -> Bool {
        let insufficentResources = resourcesToSubstract.filter { !self.isSufficent($0.key, amount: $0.value) }
        return insufficentResources.isEmpty
    }
    
    func get(_ resource: Resource) -> Int {
        return resources[resource] ?? 0
    }
}
