//
//  Entity.swift
//  VillagesTown
//
//  Created by Furkan Kaynar on 23.04.2020.
//  Copyright © 2020 Furkan Kaynar. All rights reserved.
//

import Foundation

protocol Entity {
    var isMovable: Bool { get }
    var coordinates: CGPoint { get set }
}
