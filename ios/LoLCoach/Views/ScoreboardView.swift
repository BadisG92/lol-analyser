import SwiftUI

// MARK: - ScoreboardView

/// Full 5v5 scoreboard showing all 10 players from a TAB screen extraction.
///
/// Designed for an esport/pro aesthetic — information-dense but clean, inspired
/// by op.gg and porofessor scoreboards. Uses the app's dark `DesignTokens` palette.
///
/// **Usage:**
/// ```swift
/// ScoreboardView(
///     extraction: tabScreenExtraction,
///     highlightPlayerName: "Faker"
/// )
/// ```
struct ScoreboardView: View {
    let extraction: TabScreenExtraction
    var highlightPlayerName: String?

    var body: some View {
        VStack(spacing: 0) {
            // Game time header
            gameTimeHeader

            // Blue team
            teamSection(
                team: extraction.blueTeam,
                side: .blue
            )

            // Versus divider
            versusDivider

            // Red team
            teamSection(
                team: extraction.redTeam,
                side: .red
            )
        }
        .background(DesignTokens.bgPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(hex: 0x1E293B), lineWidth: 1)
        )
    }

    // MARK: - Game Time Header

    private var gameTimeHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .font(.caption2)
                .foregroundStyle(DesignTokens.muted)

            Text("\(Int(extraction.gameTimeMinutes)):\(String(format: "%02d", Int(extraction.gameTimeMinutes.truncatingRemainder(dividingBy: 1) * 60)))")
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.7))

            if let patch = extraction.patch {
                Text("Patch \(patch)")
                    .font(.caption2)
                    .foregroundStyle(DesignTokens.muted)
            }

            Spacer()

            // Total score
            HStack(spacing: 6) {
                Text("\(extraction.blueTeam.kills)")
                    .foregroundStyle(DesignTokens.teamBlue)
                Text("-")
                    .foregroundStyle(DesignTokens.muted)
                Text("\(extraction.redTeam.kills)")
                    .foregroundStyle(DesignTokens.teamRed)
            }
            .font(.subheadline)
            .fontWeight(.bold)
            .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(DesignTokens.bgSecondary)
    }

    // MARK: - Team Section

    private func teamSection(team: TeamExtracted, side: Team) -> some View {
        VStack(spacing: 0) {
            teamHeader(team: team, side: side)

            // Player rows
            ForEach(Array(sortedPlayers(team.players).enumerated()), id: \.element.id) { index, player in
                VStack(spacing: 0) {
                    if index > 0 {
                        Divider()
                            .overlay(Color(hex: 0x1E293B).opacity(0.5))
                            .padding(.leading, 56)
                    }

                    playerRow(player: player, side: side)
                }
            }
        }
    }

    // MARK: - Team Header

    private func teamHeader(team: TeamExtracted, side: Team) -> some View {
        let color = DesignTokens.teamColor(for: side)
        let bgColor = side == .blue ? DesignTokens.teamBlueBg : DesignTokens.teamRedBg

        return HStack(spacing: 0) {
            // Team name + kills
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 3, height: 16)

                Text(side == .blue ? "Blue Team" : "Red Team")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
                    .textCase(.uppercase)

                Text("\(team.kills) kills")
                    .font(.caption2)
                    .foregroundStyle(color.opacity(0.7))
            }

            Spacer()

            // Objectives
            objectivesRow(team: team, side: side)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(bgColor.opacity(0.15))
    }

    // MARK: - Objectives Row

    private func objectivesRow(team: TeamExtracted, side: Team) -> some View {
        let color = DesignTokens.teamColor(for: side)

        return HStack(spacing: 6) {
            // Drakes
            if !team.drakes.isEmpty {
                HStack(spacing: 2) {
                    ForEach(Array(team.drakes.enumerated()), id: \.offset) { _, drake in
                        drakeIcon(drake)
                    }
                }
            }

            // Towers
            if team.towersDestroyed > 0 {
                objectiveBadge(
                    icon: "building.columns.fill",
                    value: "\(team.towersDestroyed)",
                    tint: color
                )
            }

            // Grubs
            if team.grubs > 0 {
                objectiveBadge(
                    icon: "ant.fill",
                    value: "\(team.grubs)",
                    tint: Color(hex: 0xA78BFA)
                )
            }

            // Herald
            if team.herald {
                objectivePill(
                    icon: "eye.fill",
                    label: "H",
                    tint: Color(hex: 0xA78BFA)
                )
            }

            // Baron
            if team.baron {
                objectivePill(
                    icon: "crown.fill",
                    label: "B",
                    tint: DesignTokens.gold
                )
            }
        }
    }

    private func drakeIcon(_ drakeType: String) -> some View {
        let (icon, tint) = drakeVisual(for: drakeType)
        return Image(systemName: icon)
            .font(.system(size: 10))
            .foregroundStyle(tint)
            .frame(width: 18, height: 18)
            .background(tint.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func drakeVisual(for drake: String) -> (icon: String, color: Color) {
        let lower = drake.lowercased()
        if lower.contains("infernal") || lower.contains("fire") {
            return ("flame.fill", Color(hex: 0xEF4444))
        } else if lower.contains("ocean") || lower.contains("water") {
            return ("drop.fill", Color(hex: 0x3B82F6))
        } else if lower.contains("mountain") || lower.contains("earth") {
            return ("mountain.2.fill", Color(hex: 0xA78BFA))
        } else if lower.contains("cloud") || lower.contains("air") || lower.contains("wind") {
            return ("wind", Color(hex: 0x94A3B8))
        } else if lower.contains("hextech") {
            return ("bolt.fill", Color(hex: 0x06B6D4))
        } else if lower.contains("chemtech") {
            return ("aqi.medium", Color(hex: 0x22C55E))
        } else if lower.contains("elder") {
            return ("flame.fill", DesignTokens.gold)
        }
        return ("flame.fill", Color(hex: 0x6B7280))
    }

    private func objectiveBadge(icon: String, value: String, tint: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(value)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func objectivePill(icon: String, label: String, tint: Color) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    // MARK: - Player Row

    private func playerRow(player: Player, side: Team) -> some View {
        let isHighlighted = highlightPlayerName != nil
            && player.name.lowercased() == highlightPlayerName!.lowercased()
        let teamColor = DesignTokens.teamColor(for: side)

        return HStack(spacing: 0) {
            // Champion icon + spells cluster
            HStack(spacing: 4) {
                ChampionIcon(
                    player: player,
                    size: 40,
                    showLevel: true,
                    teamColor: isHighlighted ? DesignTokens.gold : teamColor
                )

                // Summoner spells stacked vertically
                VStack(spacing: 2) {
                    ForEach(Array(player.summonerSpells.prefix(2).enumerated()), id: \.offset) { _, spell in
                        SpellIconView(spell: spell, size: 16)
                    }
                }
            }

            // Player name + role
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isHighlighted ? DesignTokens.gold : .white)
                    .lineLimit(1)
                    .truncationMode(.tail)

                HStack(spacing: 4) {
                    RoleBadge(role: player.estimatedRole, compact: true)

                    Text(player.champion)
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: 0x6B7280))
                        .lineLimit(1)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 8)

            // KDA
            VStack(alignment: .trailing, spacing: 1) {
                KDAText(
                    kills: player.kills,
                    deaths: player.deaths,
                    assists: player.assists,
                    font: .system(size: 11, weight: .semibold)
                )

                Text(kdaRatioText(player))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(kdaRatioColor(player))
            }
            .padding(.horizontal, 6)

            // CS
            VStack(spacing: 1) {
                Text("\(player.cs)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
                Text("CS")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(DesignTokens.muted)
            }
            .frame(width: 32)

            // Items
            ItemsRow(items: player.items, iconSize: 18, spacing: 1)
                .padding(.leading, 4)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            isHighlighted
                ? DesignTokens.gold.opacity(0.06)
                : Color.clear
        )
        .overlay(alignment: .leading) {
            if isHighlighted {
                Rectangle()
                    .fill(DesignTokens.gold)
                    .frame(width: 2)
            }
        }
    }

    // MARK: - Versus Divider

    private var versusDivider: some View {
        HStack(spacing: 0) {
            // Blue side gradient line
            LinearGradient(
                colors: [DesignTokens.teamBlue.opacity(0.4), DesignTokens.muted.opacity(0.3)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)

            Text("VS")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundStyle(DesignTokens.muted)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color(hex: 0x1E293B))
                )

            // Red side gradient line
            LinearGradient(
                colors: [DesignTokens.muted.opacity(0.3), DesignTokens.teamRed.opacity(0.4)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 2)
        .background(DesignTokens.bgPrimary)
    }

    // MARK: - Helpers

    /// Sort players into standard role order: Top, Jungle, Mid, ADC, Support.
    private func sortedPlayers(_ players: [Player]) -> [Player] {
        let roleOrder: [Role] = [.top, .jungle, .mid, .adc, .support]
        return players.sorted { a, b in
            let indexA = roleOrder.firstIndex(of: a.estimatedRole) ?? 5
            let indexB = roleOrder.firstIndex(of: b.estimatedRole) ?? 5
            return indexA < indexB
        }
    }

    private func kdaRatioText(_ player: Player) -> String {
        if player.deaths == 0 {
            return "Perfect"
        }
        return String(format: "%.1f", player.kdaRatio) + " KDA"
    }

    private func kdaRatioColor(_ player: Player) -> Color {
        if player.deaths == 0 {
            return DesignTokens.gold
        }
        let ratio = player.kdaRatio
        if ratio >= 5.0 {
            return DesignTokens.gold
        } else if ratio >= 3.0 {
            return Color(hex: 0x22C55E)
        } else if ratio >= 2.0 {
            return Color(hex: 0x6B7280)
        } else {
            return Color(hex: 0xEF4444).opacity(0.8)
        }
    }
}

// MARK: - Preview

#Preview("Scoreboard — Full Match") {
    let blueTeam = TeamExtracted(
        kills: 14,
        towersDestroyed: 2,
        drakes: ["Infernal", "Ocean"],
        grubs: 3,
        herald: true,
        baron: false,
        players: [
            Player(
                name: "TheShy",
                champion: "Jax",
                championIcon: nil,
                level: 13,
                kills: 4,
                deaths: 1,
                assists: 3,
                cs: 198,
                items: [
                    ItemSlot(name: "Trinity Force", icon: nil),
                    ItemSlot(name: "Plated Steelcaps", icon: nil),
                    ItemSlot(name: "Blade of the Ruined King", icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: "Stealth Ward", icon: nil),
                ],
                summonerSpells: [
                    SpellSlot(name: "Flash", icon: nil),
                    SpellSlot(name: "Teleport", icon: nil),
                ],
                estimatedRole: .top
            ),
            Player(
                name: "Canyon",
                champion: "Lee Sin",
                championIcon: nil,
                level: 11,
                kills: 3,
                deaths: 2,
                assists: 8,
                cs: 142,
                items: [
                    ItemSlot(name: "Goredrinker", icon: nil),
                    ItemSlot(name: "Ionian Boots", icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: "Oracle Lens", icon: nil),
                ],
                summonerSpells: [
                    SpellSlot(name: "Flash", icon: nil),
                    SpellSlot(name: "Smite", icon: nil),
                ],
                estimatedRole: .jungle
            ),
            Player(
                name: "Faker",
                champion: "Azir",
                championIcon: nil,
                level: 12,
                kills: 5,
                deaths: 0,
                assists: 4,
                cs: 215,
                items: [
                    ItemSlot(name: "Nashor's Tooth", icon: nil),
                    ItemSlot(name: "Sorcerer's Shoes", icon: nil),
                    ItemSlot(name: "Luden's Tempest", icon: nil),
                    ItemSlot(name: "Blasting Wand", icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: "Stealth Ward", icon: nil),
                ],
                summonerSpells: [
                    SpellSlot(name: "Flash", icon: nil),
                    SpellSlot(name: "Ignite", icon: nil),
                ],
                estimatedRole: .mid
            ),
            Player(
                name: "Gumayusi",
                champion: "Jinx",
                championIcon: nil,
                level: 11,
                kills: 2,
                deaths: 1,
                assists: 5,
                cs: 187,
                items: [
                    ItemSlot(name: "Kraken Slayer", icon: nil),
                    ItemSlot(name: "Berserker's Greaves", icon: nil),
                    ItemSlot(name: "Phantom Dancer", icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: "Stealth Ward", icon: nil),
                ],
                summonerSpells: [
                    SpellSlot(name: "Flash", icon: nil),
                    SpellSlot(name: "Heal", icon: nil),
                ],
                estimatedRole: .adc
            ),
            Player(
                name: "Keria",
                champion: "Thresh",
                championIcon: nil,
                level: 9,
                kills: 0,
                deaths: 2,
                assists: 10,
                cs: 34,
                items: [
                    ItemSlot(name: "Locket of the Iron Solari", icon: nil),
                    ItemSlot(name: "Mobility Boots", icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: "Oracle Lens", icon: nil),
                ],
                summonerSpells: [
                    SpellSlot(name: "Flash", icon: nil),
                    SpellSlot(name: "Exhaust", icon: nil),
                ],
                estimatedRole: .support
            ),
        ]
    )

    let redTeam = TeamExtracted(
        kills: 9,
        towersDestroyed: 1,
        drakes: ["Mountain"],
        grubs: 0,
        herald: false,
        baron: false,
        players: [
            Player(
                name: "Zeus",
                champion: "Gnar",
                championIcon: nil,
                level: 12,
                kills: 1,
                deaths: 3,
                assists: 2,
                cs: 175,
                items: [
                    ItemSlot(name: "Stridebreaker", icon: nil),
                    ItemSlot(name: "Plated Steelcaps", icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: "Stealth Ward", icon: nil),
                ],
                summonerSpells: [
                    SpellSlot(name: "Flash", icon: nil),
                    SpellSlot(name: "Teleport", icon: nil),
                ],
                estimatedRole: .top
            ),
            Player(
                name: "Oner",
                champion: "Vi",
                championIcon: nil,
                level: 10,
                kills: 3,
                deaths: 3,
                assists: 4,
                cs: 128,
                items: [
                    ItemSlot(name: "Eclipse", icon: nil),
                    ItemSlot(name: "Ionian Boots", icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: "Oracle Lens", icon: nil),
                ],
                summonerSpells: [
                    SpellSlot(name: "Flash", icon: nil),
                    SpellSlot(name: "Smite", icon: nil),
                ],
                estimatedRole: .jungle
            ),
            Player(
                name: "Chovy",
                champion: "Orianna",
                championIcon: nil,
                level: 12,
                kills: 2,
                deaths: 2,
                assists: 3,
                cs: 208,
                items: [
                    ItemSlot(name: "Luden's Tempest", icon: nil),
                    ItemSlot(name: "Sorcerer's Shoes", icon: nil),
                    ItemSlot(name: "Shadowflame", icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: "Stealth Ward", icon: nil),
                ],
                summonerSpells: [
                    SpellSlot(name: "Flash", icon: nil),
                    SpellSlot(name: "Teleport", icon: nil),
                ],
                estimatedRole: .mid
            ),
            Player(
                name: "Peyz",
                champion: "Kai'Sa",
                championIcon: nil,
                level: 11,
                kills: 3,
                deaths: 3,
                assists: 2,
                cs: 179,
                items: [
                    ItemSlot(name: "Kraken Slayer", icon: nil),
                    ItemSlot(name: "Berserker's Greaves", icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: "Stealth Ward", icon: nil),
                ],
                summonerSpells: [
                    SpellSlot(name: "Flash", icon: nil),
                    SpellSlot(name: "Heal", icon: nil),
                ],
                estimatedRole: .adc
            ),
            Player(
                name: "BeryL",
                champion: "Lulu",
                championIcon: nil,
                level: 9,
                kills: 0,
                deaths: 3,
                assists: 7,
                cs: 28,
                items: [
                    ItemSlot(name: "Moonstone Renewer", icon: nil),
                    ItemSlot(name: "Ionian Boots", icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: nil, icon: nil),
                    ItemSlot(name: "Oracle Lens", icon: nil),
                ],
                summonerSpells: [
                    SpellSlot(name: "Flash", icon: nil),
                    SpellSlot(name: "Exhaust", icon: nil),
                ],
                estimatedRole: .support
            ),
        ]
    )

    let extraction = TabScreenExtraction(
        patch: "14.10",
        gameTimeMinutes: 18.5,
        blueTeam: blueTeam,
        redTeam: redTeam,
        minimapObservations: "Blue team has vision control around baron pit.",
        additionalObservations: "Faker is on a killing spree."
    )

    ScrollView {
        ScoreboardView(
            extraction: extraction,
            highlightPlayerName: "Faker"
        )
        .padding(.horizontal, 8)
        .padding(.top, 16)
    }
    .background(DesignTokens.bgPrimary)
    .preferredColorScheme(.dark)
}
