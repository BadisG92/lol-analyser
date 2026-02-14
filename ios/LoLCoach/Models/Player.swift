import Foundation

enum Region: String, Codable, CaseIterable, Identifiable {
    case euw1, na1, kr, eun1, br1, jp1, la1, la2, oc1, tr1, ru
    case ph2, sg2, th2, tw2, vn2

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .euw1: "Europe West"
        case .na1: "North America"
        case .kr: "Korea"
        case .eun1: "Europe Nordic & East"
        case .br1: "Brazil"
        case .jp1: "Japan"
        case .la1: "Latin America North"
        case .la2: "Latin America South"
        case .oc1: "Oceania"
        case .tr1: "Turkey"
        case .ru: "Russia"
        case .ph2: "Philippines"
        case .sg2: "Singapore"
        case .th2: "Thailand"
        case .tw2: "Taiwan"
        case .vn2: "Vietnam"
        }
    }
}

enum Role: String, Codable, CaseIterable, Identifiable {
    case top, jungle, mid, adc, support

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .top: "Top"
        case .jungle: "Jungle"
        case .mid: "Mid"
        case .adc: "ADC"
        case .support: "Support"
        }
    }
}

enum Team: String, Codable {
    case blue, red
}

// MARK: - Item & Spell with DDragon icons

struct ItemSlot: Codable {
    let name: String?
    let icon: String?

    /// Display name (or "Empty" for empty slots).
    var displayName: String { name ?? "Empty" }

    /// DDragon icon URL, if available.
    var iconURL: URL? {
        guard let icon else { return nil }
        return URL(string: icon)
    }
}

struct SpellSlot: Codable {
    let name: String
    let icon: String?

    var iconURL: URL? {
        guard let icon else { return nil }
        return URL(string: icon)
    }
}

// MARK: - Player (enriched with DDragon images)

struct Player: Codable, Identifiable {
    var id: String { name }

    let name: String
    let champion: String
    let championIcon: String?
    let level: Int
    let kills: Int
    let deaths: Int
    let assists: Int
    let cs: Int
    let items: [ItemSlot]
    let summonerSpells: [SpellSlot]
    let estimatedRole: Role

    var kda: String {
        "\(kills)/\(deaths)/\(assists)"
    }

    var kdaRatio: Double {
        deaths == 0 ? Double(kills + assists) : Double(kills + assists) / Double(deaths)
    }

    var championIconURL: URL? {
        guard let championIcon else { return nil }
        return URL(string: championIcon)
    }

    /// Completed items only (non-null names).
    var completedItems: [ItemSlot] {
        items.filter { $0.name != nil }
    }

    enum CodingKeys: String, CodingKey {
        case name, champion, level, kills, deaths, assists, cs, items
        case championIcon = "champion_icon"
        case summonerSpells = "summoner_spells"
        case estimatedRole = "estimated_role"
    }
}
