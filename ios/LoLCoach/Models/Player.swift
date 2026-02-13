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

struct Player: Codable, Identifiable {
    var id: String { name }

    let name: String
    let champion: String
    let level: Int
    let kills: Int
    let deaths: Int
    let assists: Int
    let cs: Int
    let items: [String]
    let summonerSpells: [String]
    let estimatedRole: Role

    var kda: String {
        "\(kills)/\(deaths)/\(assists)"
    }

    var kdaRatio: Double {
        deaths == 0 ? Double(kills + assists) : Double(kills + assists) / Double(deaths)
    }

    enum CodingKeys: String, CodingKey {
        case name, champion, level, kills, deaths, assists, cs, items
        case summonerSpells = "summoner_spells"
        case estimatedRole = "estimated_role"
    }
}
