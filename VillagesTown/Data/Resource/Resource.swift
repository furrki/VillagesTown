//
//  Resource.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 10.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import SwiftUI

enum Resource: Hashable {
    case iron
    
    var name: String {
        switch self {
        case .iron:
            return "Iron"
        }
    }
    
    var group: Group {
        switch self {
        case .iron:
            return .raw
        }
    }
    
    var color: Color {
        switch self {
        case .iron:
            return .gray
        }
    }
    
    // MARK: - Hashable
    static func == (lhs: Resource, rhs: Resource) -> Bool {
        lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name.hashValue)
    }
    
    // MARK: - Enums
    enum Group {
        case raw
        case processed
    }
    
    // MARK: - Static Methods
    static func getAll() -> [Resource] {
        return [.iron]
    }
}
