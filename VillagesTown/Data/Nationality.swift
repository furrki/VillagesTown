//
//  Nationality.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 10.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import Foundation

struct Nationality {
    let id = UUID()
    let name: String
    let flag: String
    
    static func getAll() -> [Nationality] {
        return [Nationality(name: "Turkish", flag: "🇹🇷"),
                Nationality(name: "Greek", flag: "🇬🇷"),
                Nationality(name: "Bulgarian", flag: "🇧🇬")]
    }
}
