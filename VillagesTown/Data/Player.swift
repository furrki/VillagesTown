//
//  Player.swift
//  VillagesTown
//
//  Created by Claude Code
//

import Foundation

struct Player {
    let id: String
    let name: String
    let nationality: Nationality
    let isHuman: Bool
    var villages: [String] = [] // Village IDs
    var isEliminated: Bool = false

    // AI Personality
    var aiPersonality: AIPersonality?

    enum AIPersonality {
        case aggressive  // Early military, constant expansion
        case economic    // Build tall, strong economy
        case balanced    // Mix of both

        var description: String {
            switch self {
            case .aggressive: return "Aggressive Conqueror"
            case .economic: return "Economic Powerhouse"
            case .balanced: return "Balanced Strategist"
            }
        }
    }

    init(id: String, name: String, nationality: Nationality, isHuman: Bool, aiPersonality: AIPersonality? = nil) {
        self.id = id
        self.name = name
        self.nationality = nationality
        self.isHuman = isHuman
        self.aiPersonality = aiPersonality
    }

    static func createPlayers() -> [Player] {
        return [
            Player(id: "player", name: "Your Empire", nationality: Nationality.getAll()[0], isHuman: true),
            Player(id: "ai1", name: "Greek Empire", nationality: Nationality.getAll()[1], isHuman: false, aiPersonality: .economic),
            Player(id: "ai2", name: "Bulgarian Kingdom", nationality: Nationality.getAll()[2], isHuman: false, aiPersonality: .balanced)
        ]
    }
}
