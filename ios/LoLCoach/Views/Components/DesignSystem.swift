import SwiftUI

// MARK: - DDragonImage

/// Cached AsyncImage wrapper for DDragon CDN icons.
/// Shows a placeholder while loading and a fallback on failure.
struct DDragonImage: View {
    let url: URL?
    var size: CGFloat = 32

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fill)
            case .failure:
                fallbackView
            case .empty:
                ProgressView()
                    .frame(width: size, height: size)
            @unknown default:
                fallbackView
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size > 28 ? 8 : 4))
    }

    private var fallbackView: some View {
        RoundedRectangle(cornerRadius: size > 28 ? 8 : 4)
            .fill(Color(hex: 0x1E293B))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "questionmark")
                    .font(.system(size: size * 0.35))
                    .foregroundStyle(Color(hex: 0x3B4A6B))
            }
    }
}

// MARK: - ChampionIcon

/// Champion portrait from DDragon with optional level badge and team border.
struct ChampionIcon: View {
    let player: Player
    var size: CGFloat = 40
    var showLevel: Bool = true
    var teamColor: Color? = nil

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            DDragonImage(url: player.championIconURL, size: size)
                .overlay {
                    if let teamColor {
                        RoundedRectangle(cornerRadius: size > 28 ? 8 : 4)
                            .strokeBorder(teamColor, lineWidth: 2)
                    }
                }

            if showLevel {
                Text("\(player.level)")
                    .font(.system(size: max(8, size * 0.25), weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(Color.black.opacity(0.75))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .offset(x: 2, y: 2)
            }
        }
    }
}

// MARK: - ItemIconView

/// Compact item icon from DDragon. Null items show as empty dark slots.
struct ItemIconView: View {
    let item: ItemSlot
    var size: CGFloat = 22

    var body: some View {
        if let url = item.iconURL {
            DDragonImage(url: url, size: size)
        } else {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: 0x111827))
                .frame(width: size, height: size)
                .overlay {
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(Color(hex: 0x1E293B), lineWidth: 0.5)
                }
        }
    }
}

// MARK: - SpellIconView

/// Summoner spell icon from DDragon.
struct SpellIconView: View {
    let spell: SpellSlot
    var size: CGFloat = 18

    var body: some View {
        DDragonImage(url: spell.iconURL, size: size)
    }
}

// MARK: - ItemsRow

/// Horizontal row of item icons (up to 7 slots).
struct ItemsRow: View {
    let items: [ItemSlot]
    var iconSize: CGFloat = 20
    var spacing: CGFloat = 2

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(Array(items.prefix(7).enumerated()), id: \.offset) { _, item in
                ItemIconView(item: item, size: iconSize)
            }
            // Fill remaining empty slots
            if items.count < 7 {
                ForEach(items.count..<7, id: \.self) { _ in
                    ItemIconView(item: ItemSlot(name: nil, icon: nil), size: iconSize)
                }
            }
        }
    }
}

// MARK: - KDAText

/// Styled KDA display: green kills, gray deaths, yellow assists.
struct KDAText: View {
    let kills: Int
    let deaths: Int
    let assists: Int
    var font: Font = .caption

    var body: some View {
        HStack(spacing: 1) {
            Text("\(kills)")
                .foregroundStyle(Color(hex: 0x22C55E))
            Text("/")
                .foregroundStyle(Color(hex: 0x3B4A6B))
            Text("\(deaths)")
                .foregroundStyle(deaths > 0 ? Color(hex: 0xEF4444) : Color(hex: 0x6B7280))
            Text("/")
                .foregroundStyle(Color(hex: 0x3B4A6B))
            Text("\(assists)")
                .foregroundStyle(Color(hex: 0xC89B3C))
        }
        .font(font)
        .fontWeight(.semibold)
        .monospacedDigit()
    }
}

// MARK: - RoleBadge

/// Compact role indicator with icon.
struct RoleBadge: View {
    let role: Role
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: roleIcon)
                .font(.system(size: compact ? 8 : 10))
            if !compact {
                Text(role.displayName)
                    .font(.caption2)
            }
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, compact ? 4 : 6)
        .padding(.vertical, 2)
        .background(Color(hex: 0x1E293B))
        .clipShape(Capsule())
    }

    private var roleIcon: String {
        switch role {
        case .top: "arrow.up.square"
        case .jungle: "leaf"
        case .mid: "diamond"
        case .adc: "scope"
        case .support: "cross.circle"
        }
    }
}

// MARK: - GlowButton

/// Prominent CTA button with glow effect.
struct GlowButton: View {
    let title: String
    let icon: String
    var gradient: [Color] = [Color(hex: 0x0A5CA8), Color(hex: 0x0D7FD9)]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: gradient,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: gradient.last!.opacity(0.4), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Color Extension (ensure available project-wide)

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}

// MARK: - Design Constants

enum DesignTokens {
    // Background
    static let bgPrimary = Color(hex: 0x0A0E1A)
    static let bgSecondary = Color(hex: 0x111827)
    static let bgCard = Color(hex: 0x1A1F2E)
    static let bgCardHover = Color(hex: 0x1E293B)

    // Accent
    static let gold = Color(hex: 0xC89B3C)
    static let goldLight = Color(hex: 0xD4A944)
    static let blue = Color(hex: 0x0D7FD9)
    static let blueDeep = Color(hex: 0x0A5CA8)

    // Team
    static let teamBlue = Color(hex: 0x4A9EEF)
    static let teamRed = Color(hex: 0xEF4444)
    static let teamBlueBg = Color(hex: 0x0A5CA8)
    static let teamRedBg = Color(hex: 0x9B2C2C)

    // Status
    static let phaseEarly = Color(hex: 0x22C55E)
    static let phaseMid = Color(hex: 0xF59E0B)
    static let phaseLate = Color(hex: 0xEF4444)
    static let muted = Color(hex: 0x3B4A6B)

    // Gradient
    static let bgGradient = LinearGradient(
        colors: [bgPrimary, bgSecondary],
        startPoint: .top,
        endPoint: .bottom
    )

    static let blueGradient = LinearGradient(
        colors: [blueDeep, blue],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let goldGradient = LinearGradient(
        colors: [gold, goldLight],
        startPoint: .leading,
        endPoint: .trailing
    )

    static func phaseColor(for phase: GamePhase) -> Color {
        switch phase {
        case .early: phaseEarly
        case .mid: phaseMid
        case .late: phaseLate
        }
    }

    static func teamColor(for team: Team) -> Color {
        team == .blue ? teamBlue : teamRed
    }
}
