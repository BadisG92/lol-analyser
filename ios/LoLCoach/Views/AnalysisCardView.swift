import SwiftUI

// MARK: - AnalysisCardView

/// Displays a single screenshot analysis as a collapsible card.
///
/// Shows game stats (score, towers, drakes) in a compact bar,
/// then parses the coaching text into thematic sections with icons:
/// SITUATION, ACTION, BUILD, OBJECTIFS, TEAMFIGHT, WIN CONDITION, ERREUR.
struct AnalysisCardView: View {
    let analysis: ScreenshotAnalysis

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeader

            if isExpanded {
                Divider()
                    .overlay(Color(hex: 0x1E293B))

                statsBar

                Divider()
                    .overlay(Color(hex: 0x1E293B))

                coachingContent
            }
        }
        .background(Color(hex: 0x1A1F2E))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(hex: 0x1E293B), lineWidth: 1)
        )
    }

    // MARK: - Header

    private var cardHeader: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 10) {
                // Phase badge
                Text(analysis.gamePhase.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(phaseColor)
                    .clipShape(Capsule())

                // Time
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("\(Int(analysis.extraction.gameTimeMinutes)) min")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)

                Spacer()

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: 0) {
            statColumn(
                icon: "sword.circle",
                label: "Score",
                blueValue: "\(analysis.extraction.blueTeam.kills)",
                redValue: "\(analysis.extraction.redTeam.kills)"
            )

            Divider()
                .frame(height: 32)
                .overlay(Color(hex: 0x1E293B))

            statColumn(
                icon: "building.columns",
                label: "Tours",
                blueValue: "\(analysis.extraction.blueTeam.towersDestroyed)",
                redValue: "\(analysis.extraction.redTeam.towersDestroyed)"
            )

            Divider()
                .frame(height: 32)
                .overlay(Color(hex: 0x1E293B))

            statColumn(
                icon: "flame",
                label: "Drakes",
                blueValue: "\(analysis.extraction.blueTeam.drakes.count)",
                redValue: "\(analysis.extraction.redTeam.drakes.count)"
            )
        }
        .padding(.vertical, 8)
    }

    private func statColumn(icon: String, label: String, blueValue: String, redValue: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Text(blueValue)
                    .foregroundStyle(Color(hex: 0x4A9EEF))
                Text("-")
                    .foregroundStyle(.secondary)
                Text(redValue)
                    .foregroundStyle(Color(hex: 0xEF4444))
            }
            .font(.subheadline)
            .fontWeight(.semibold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Coaching Content

    private var coachingContent: some View {
        VStack(alignment: .leading, spacing: 12) {
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

    private func coachingSectionView(_ section: CoachingSection) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(section.icon)
                    .font(.subheadline)

                Text(section.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(section.color)
            }

            Text(section.content)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(section.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Phase Color

    private var phaseColor: Color {
        switch analysis.gamePhase {
        case .early: Color(hex: 0x22C55E)
        case .mid: Color(hex: 0xF59E0B)
        case .late: Color(hex: 0xEF4444)
        }
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

            var matched = false
            for pattern in patterns {
                if trimmed.uppercased().hasPrefix(pattern.keyword) {
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
        AnalysisCardView(
            analysis: ScreenshotAnalysis(
                id: "preview-1",
                timestamp: 15.5,
                extraction: TabScreenExtraction(
                    gameTimeMinutes: 15.5,
                    blueTeam: TeamExtracted(
                        kills: 8,
                        towersDestroyed: 1,
                        drakes: ["Infernal"],
                        grubs: 2,
                        herald: true,
                        baron: false,
                        players: []
                    ),
                    redTeam: TeamExtracted(
                        kills: 5,
                        towersDestroyed: 0,
                        drakes: [],
                        grubs: 0,
                        herald: false,
                        baron: false,
                        players: []
                    ),
                    minimapObservations: "Good vision",
                    additionalObservations: ""
                ),
                coaching: """
                SITUATION ACTUELLE: Vous etes en avantage de 3 kills avec un lead de CS confortable.

                ACTION IMMEDIATE: Push mid et roam bot pour le drake.

                BUILD RECOMMANDE: Finissez votre item mythique et prenez des bottes.

                OBJECTIFS: Dragon infernal dans 45 secondes. Preparez la vision.

                TEAMFIGHT: Focus le carry AD ennemi. Gardez votre ultime pour le disengage.

                WIN CONDITION: Votre composition scale mieux. Jouez pour le late game.
                """,
                gamePhase: .mid
            )
        )
        .padding()
    }
    .background(Color(hex: 0x0A0E1A))
    .preferredColorScheme(.dark)
}
