//
//  Village+Enums.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 10.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import Foundation

extension Village {
    // MARK: - Enums
    enum Level: Int {
        case village = 1
        case town = 2
        case district = 3
        case castle = 4
        case city = 5
        
        var value: Int {
            return self.rawValue
        }
    }
}
