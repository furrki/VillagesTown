//
//  TreasuryHolder.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 23.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import Foundation

protocol TreasuryHolder {
    var money: Double { get set }
}

extension TreasuryHolder {
    mutating func add(money: Double) {
        if money > 0 {
            self.money += money
        }
    }
    
    mutating func substract(money: Double) {
        if isSufficent(money: money) {
            self.money -= money
        }
    }
    
    private func isSufficent(money: Double) -> Bool {
        return money <= self.money && money > 0
    }
}
