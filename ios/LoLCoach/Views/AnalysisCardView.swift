import SwiftUI

// MARK: - AnalysisCardView

/// Displays a single screenshot analysis as a collapsible card with a
/// game-HUD-style scoreboard, drake/objective icons, and themed coaching sections.
struct AnalysisCardView: View {
    let analysis: ScreenshotAnalysis

    @State private var isExpanded = true

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeader

            if isExpanded {
                // Gold accent line under header
                Rectangle()
                    .fill(DesignTokens.gold.opacity(0.5))
                    .frame(height: 1)

                statsBar

                Divider()
                    .overlay(DesignTokens.bgCardHover)

                objectivesBar

                Divider()
                    .overlay(DesignTokens.bgCardHover)

                coachingContent
            }
        }
        .background(DesignTokens.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(DesignTokens.bgCardHover, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }

    // MARK: - Header

    private var cardHeader: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 10) {
                // Phase badge with glow
                Text(analysis.gamePhase.displayName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .textCase(.uppercase)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(DesignTokens.phaseColor(for: analysis.gamePhase))
                    )
                    .overlay(
                        Capsule()
                            .stroke(DesignTokens.phaseColor(for: analysis.gamePhase).opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: DesignTokens.phaseColor(for: analysis.gamePhase).opacity(0.5), radius: 6, y: 0)

                // Game time
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                    Text("\(Int(analysis.extraction.gameTimeMinutes)) min")
                        .font(.callout)
                        .fontWeight(.medium)
                }
                .foregroundStyle(DesignTokens.muted)

                // Patch badge if present
                if let patch = analysis.extraction.patch {
                    Text("v\(patch)")
                        .font(.caption2)
                        .foregroundStyle(DesignTokens.muted)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(DesignTokens.bgCardHover)
                        .clipShape(Capsule())
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignTokens.muted)
                    .rotationEffect(.degrees(isExpanded ? -180 : 0))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats Bar (Mini Scoreboard)

    private var statsBar: some View {
        HStack(spacing: 0) {
            // Blue side
            VStack(spacing: 2) {
                Text("BLUE")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(DesignTokens.teamBlue.opacity(0.7))
                    .tracking(1)
            }
            .frame(width: 50)

            Spacer()

            // Score
            HStack(spacing: 12) {
                Text("\(analysis.extraction.blueTeam.kills)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(DesignTokens.teamBlue)
                    .monospacedDigit()

                // Swords divider
                VStack(spacing: 2) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(DesignTokens.gold)
                    Text("VS")
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .foregroundStyle(DesignTokens.muted)
                }

                Text("\(analysis.extraction.redTeam.kills)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(DesignTokens.teamRed)
                    .monospacedDigit()
            }

            Spacer()

            // Red side
            VStack(spacing: 2) {
                Text("RED")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(DesignTokens.teamRed.opacity(0.7))
                    .tracking(1)
            }
            .frame(width: 50)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                stops: [
                    .init(color: DesignTokens.teamBlue.opacity(0.06), location: 0),
                    .init(color: .clear, location: 0.4),
                    .init(color: .clear, location: 0.6),
                    .init(color: DesignTokens.teamRed.opacity(0.06), location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    // MARK: - Objectives Bar

    private var objectivesBar: some View {
        HStack(spacing: 0) {
            // Blue objectives
            objectivesForTeam(analysis.extraction.blueTeam, color: DesignTokens.teamBlue)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Tower count center
            HStack(spacing: 6) {
                Text("\(analysis.extraction.blueTeam.towersDestroyed)")
                    .foregroundStyle(DesignTokens.teamBlue)
                Text("🏰")
                Text("\(analysis.extraction.redTeam.towersDestroyed)")
                    .foregroundStyle(DesignTokens.teamRed)
            }
            .font(.subheadline)
            .fontWeight(.bold)
            .monospacedDigit()

            // Red objectives
            objectivesForTeam(analysis.extraction.redTeam, color: DesignTokens.teamRed)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func objectivesForTeam(_ team: TeamExtracted, color: Color) -> some View {
        HStack(spacing: 4) {
            // Drakes
            ForEach(Array(team.drakes.enumerated()), id: \.offset) { _, drake in
                Text(drakeEmoji(for: drake))
                    .font(.system(size: 14))
            }

            // Grubs
            if team.grubs > 0 {
                HStack(spacing: 1) {
                    Text("\u{1FAB2}")
                        .font(.system(size: 13))
                    Text("\(team.grubs)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                }
            }

            // Herald
            if team.herald {
                Text("\u{1F980}")
                    .font(.system(size: 13))
            }

            // Baron
            if team.baron {
                Text("\u{1F7E3}")
                    .font(.system(size: 13))
            }
        }
    }

    private func drakeEmoji(for drake: String) -> String {
        let lower = drake.lowercased()
        if lower.contains("infernal") || lower.contains("inferno") { return "\u{1F525}" }
        if lower.contains("mountain") { return "\u{1F3D4}\u{FE0F}" }
        if lower.contains("ocean") { return "\u{1F30A}" }
        if lower.contains("cloud") { return "\u{1F4A8}" }
        if lower.contains("hextech") { return "\u{26A1}" }
        if lower.contains("chemtech") { return "\u{2623}\u{FE0F}" }
        // Fallback dragon
        return "\u{1F409}"
    }

    // MARK: - Coaching Content

    private var coachingContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            let sections = Self.parseCoachingSections(analysis.coaching)

            if sections.isEmpty {
                // Raw text fallback
                Text(analysis.coaching)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineSpacing(4)
            } else {
                ForEach(sections) { section in
                    coachingSectionView(section)
                }
            }
        }
        .padding(16)
        .textSelection(.enabled)
    }

    /// Known item names to detect and bold within BUILD section content.
    private static let knownItemKeywords: [String] = [
        // Mythics / popular items
        "Infinity Edge", "Rabadon", "Zhonya", "Morellonomicon", "Void Staff",
        "Luden", "Crown", "Liandry", "Riftmaker", "Everfrost",
        "Trinity Force", "Divine Sunderer", "Goredrinker", "Stridebreaker",
        "Galeforce", "Kraken Slayer", "Immortal Shieldbow",
        "Sunfire", "Frostfire", "Turbo Chemtank",
        "Moonstone", "Shurelya", "Imperial Mandate",
        // Boots
        "Berserker", "Sorcerer", "Plated Steelcaps", "Mercury",
        "Boots of Swiftness", "Ionian", "Lucidity",
        "bottes", "Bottes",
        // Common items (FR + EN)
        "Blade of the Ruined King", "BORK", "BotRK",
        "Nashor", "Wit's End", "Phantom Dancer", "Rapid Firecannon",
        "Thornmail", "Randuin", "Spirit Visage", "Force of Nature",
        "Warmog", "Guardian Angel", "Banshee", "Edge of Night",
        "Serpent", "Mortal Reminder", "Lord Dominik",
        "Seraph", "Manamune", "Muramana", "Archangel",
        "Hextech Rocketbelt", "Protobelt", "Night Harvester",
        "Duskblade", "Eclipse", "Prowler", "Youmuu",
        "Black Cleaver", "Death's Dance", "Sterak", "Maw",
        "Redemption", "Staff of Flowing Water", "Ardent",
        "Mikael", "Chemtech Putrifier",
        "Collector", "Stormrazor", "Navori",
        "Rageblade", "Runaan",
        "Demonic Embrace", "Cosmic Drive", "Shadowflame",
        "Jak'Sho", "Radiant Virtue", "Heartsteel",
        "Rod of Ages", "Catalyst",
        "Statikk", "Experimental Hexplate", "Voltaic Cyclosword",
        "Hubris", "Opportunity", "Profane Hydra",
        "item mythique", "item legendaire",
    ]

    /// Returns an AttributedString with known item names bolded (for BUILD sections).
    private static func attributedBuildContent(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)

        for keyword in knownItemKeywords {
            var searchRange = attributed.startIndex..<attributed.endIndex
            while let range = attributed[searchRange].range(of: keyword, options: .caseInsensitive) {
                attributed[range].font = .subheadline.bold()
                attributed[range].foregroundColor = .white
                if range.upperBound < attributed.endIndex {
                    searchRange = range.upperBound..<attributed.endIndex
                } else {
                    break
                }
            }
        }

        return attributed
    }

    private func coachingSectionView(_ section: CoachingSection) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Colored left accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(section.color)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 8) {
                // Section header
                HStack(spacing: 6) {
                    Text(section.icon)
                        .font(.callout)

                    Text(section.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(section.color)
                }

                // Section content
                if section.title == "BUILD" {
                    Text(Self.attributedBuildContent(section.content))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.88))
                        .lineSpacing(4)
                } else {
                    Text(section.content)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.88))
                        .lineSpacing(4)
                }
            }
            .padding(.leading, 12)
            .padding(.vertical, 2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.bgSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Section Model

    struct CoachingSection: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let content: String
        let color: Color
    }

    // MARK: - Section Parsing

    /// Parses coaching text into structured sections based on known header keywords.
    ///
    /// Recognises headers like "SITUATION ACTUELLE:", "ACTION IMMEDIATE:", etc.
    /// Returns an empty array if no sections are found (fallback to raw text).
    static func parseCoachingSections(_ text: String) -> [CoachingSection] {
        let patterns: [(keyword: String, icon: String, title: String, color: Color)] = [
            ("SITUATION",     "\u{1F6A8}", "SITUATION",     Color(hex: 0xF59E0B)),
            ("ACTION",        "\u{26A1}",  "ACTION",        Color(hex: 0x0D7FD9)),
            ("BUILD",         "\u{1F6D2}", "BUILD",         Color(hex: 0x8B5CF6)),
            ("OBJECTIF",      "\u{1F3AF}", "OBJECTIFS",     Color(hex: 0x22C55E)),
            ("TEAMFIGHT",     "\u{2694}\u{FE0F}", "TEAMFIGHT", Color(hex: 0xEF4444)),
            ("WIN CONDITION", "\u{1F3C6}", "WIN CONDITION", Color(hex: 0xC89B3C)),
            ("ERREUR",        "\u{26A0}\u{FE0F}", "ERREUR", Color(hex: 0xEF4444)),
        ]

        var sections: [CoachingSection] = []
        let lines = text.components(separatedBy: "\n")
        var currentMatch: (icon: String, title: String, color: Color)?
        var currentContent: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            // Strip leading markdown bold markers (**), emojis, and other
            // non-letter characters so that "**🚨 SITUATION**" matches the
            // keyword "SITUATION". Without this, the hasPrefix check fails
            // because Claude's response wraps headers in ** and emoji prefixes.
            let stripped = String(
                trimmed.drop { !$0.isASCII || !$0.isLetter }
            )
            .trimmingCharacters(in: .whitespaces)
            // Also remove trailing ** if present
            .replacingOccurrences(of: "**", with: "")
            .trimmingCharacters(in: .whitespaces)

            var matched = false
            for pattern in patterns {
                if stripped.uppercased().hasPrefix(pattern.keyword) {
                    // Flush previous section
                    if let current = currentMatch, !currentContent.isEmpty {
                        sections.append(CoachingSection(
                            icon: current.icon,
                            title: current.title,
                            content: currentContent.joined(separator: " "),
                            color: current.color
                        ))
                    }

                    currentMatch = (pattern.icon, pattern.title, pattern.color)
                    currentContent = []

                    // Extract inline content after the colon
                    let parts = trimmed.split(separator: ":", maxSplits: 1)
                    if parts.count > 1 {
                        let afterColon = String(parts[1]).trimmingCharacters(in: .whitespaces)
                        if !afterColon.isEmpty {
                            currentContent.append(afterColon)
                        }
                    }

                    matched = true
                    break
                }
            }

            if !matched {
                currentContent.append(trimmed)
            }
        }

        // Flush last section
        if let current = currentMatch, !currentContent.isEmpty {
            sections.append(CoachingSection(
                icon: current.icon,
                title: current.title,
                content: currentContent.joined(separator: " "),
                color: current.color
            ))
        }

        return sections
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            // Card 1 — Mid game with objectives
            AnalysisCardView(
                analysis: ScreenshotAnalysis(
                    id: "preview-1",
                    timestamp: 15.5,
                    extraction: TabScreenExtraction(
                        patch: "14.10",
                        gameTimeMinutes: 15.5,
                        blueTeam: TeamExtracted(
                            kills: 12,
                            towersDestroyed: 2,
                            drakes: ["Infernal", "Ocean"],
                            grubs: 3,
                            herald: true,
                            baron: false,
                            players: []
                        ),
                        redTeam: TeamExtracted(
                            kills: 7,
                            towersDestroyed: 1,
                            drakes: ["Mountain"],
                            grubs: 0,
                            herald: false,
                            baron: false,
                            players: []
                        ),
                        minimapObservations: "Good vision around dragon pit",
                        additionalObservations: ""
                    ),
                    coaching: """
                    SITUATION ACTUELLE: Vous etes en avantage de 5 kills avec un lead de CS confortable. Deux drakes securises, bonne pression sur la map.

                    ACTION IMMEDIATE: Push mid et roam bot pour le prochain drake. Placez une ward de controle dans la riviere.

                    BUILD RECOMMANDE: Finissez votre Infinity Edge et prenez des Berserker Greaves. Ensuite visez un Phantom Dancer pour le DPS.

                    OBJECTIFS: Dragon Ocean dans 45 secondes. Preparez la vision. Herald peut etre trade si necessaire.

                    TEAMFIGHT: Focus le carry AD ennemi. Gardez votre ultime pour le disengage. Positionnez-vous derriere votre frontline.

                    WIN CONDITION: Votre composition scale mieux en late game. Accumulez les drakes et jouez pour l'ame.

                    ERREUR A EVITER: Ne pas overchase apres les kills. Convertissez les avantages en objectifs.
                    """,
                    gamePhase: .mid
                )
            )

            // Card 2 — Late game with baron
            AnalysisCardView(
                analysis: ScreenshotAnalysis(
                    id: "preview-2",
                    timestamp: 32.0,
                    extraction: TabScreenExtraction(
                        patch: nil,
                        gameTimeMinutes: 32.0,
                        blueTeam: TeamExtracted(
                            kills: 22,
                            towersDestroyed: 6,
                            drakes: ["Infernal", "Ocean", "Cloud"],
                            grubs: 5,
                            herald: true,
                            baron: true,
                            players: []
                        ),
                        redTeam: TeamExtracted(
                            kills: 18,
                            towersDestroyed: 3,
                            drakes: ["Hextech", "Chemtech"],
                            grubs: 1,
                            herald: false,
                            baron: false,
                            players: []
                        ),
                        minimapObservations: "Baron buff active, pushing top",
                        additionalObservations: ""
                    ),
                    coaching: """
                    SITUATION ACTUELLE: Baron buff actif. Avantage significatif en or et en objectifs. C'est le moment de closer.

                    ACTION IMMEDIATE: Group mid avec le baron buff et forcez les tourelles. Ne splitpush pas seul.

                    WIN CONDITION: Avec trois drakes et le baron, un dernier teamfight gagne vous donne le nexus.
                    """,
                    gamePhase: .late
                )
            )
        }
        .padding()
    }
    .background(DesignTokens.bgPrimary)
    .preferredColorScheme(.dark)
}
