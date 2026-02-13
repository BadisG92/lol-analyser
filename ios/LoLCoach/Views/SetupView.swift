import SwiftUI

// MARK: - SetupView

/// Onboarding / settings screen where the player enters their Riot ID and region.
///
/// Shown as a sheet on first launch (when `appState.isSetupComplete` is false)
/// and accessible later via the gear icon on the home screen.
struct SetupView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    /// When `true`, SetupView wraps itself in a NavigationStack (for sheet presentation).
    /// When `false`, it assumes it is already inside a NavigationStack (e.g. embedded in ContentView).
    var wrapsInNavigationStack: Bool = true

    @State private var riotId: String = ""
    @State private var selectedRegion: Region = .euw1
    @State private var showError = false
    @State private var errorMessage = ""

    /// Validates that the Riot ID contains exactly one `#` with non-empty parts.
    private var isValid: Bool {
        let trimmed = riotId.trimmingCharacters(in: .whitespaces)
        guard trimmed.contains("#") else { return false }
        let parts = trimmed.split(separator: "#")
        return parts.count == 2 && !parts[0].isEmpty && !parts[1].isEmpty
    }

    var body: some View {
        if wrapsInNavigationStack {
            NavigationStack {
                formContent
            }
        } else {
            formContent
        }
    }

    private var formContent: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x0A0E1A), Color(hex: 0x111827)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 36) {
                    welcomeSection
                    formSection
                    submitButton
                    infoSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle("Configuration")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            if appState.isSetupComplete {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundStyle(Color(hex: 0xC89B3C))
                }
            }
        }
        .onAppear {
            if appState.isSetupComplete {
                riotId = appState.riotId
                selectedRegion = appState.region
            }
        }
        .alert("Erreur", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Welcome

    private var welcomeSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0x0A5CA8), Color(hex: 0x0D7FD9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color(hex: 0xC89B3C))
            }

            Text("LoL AI Coach")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("Coaching tactique en temps reel\npendant vos games")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(spacing: 20) {
            // Riot ID
            VStack(alignment: .leading, spacing: 8) {
                Text("Riot ID")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                TextField("PlayerName#EUW", text: $riotId)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .padding(14)
                    .background(Color(hex: 0x1E293B))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                riotId.isEmpty
                                    ? Color.clear
                                    : (isValid ? Color(hex: 0x22C55E) : Color(hex: 0xEF4444)),
                                lineWidth: 1.5
                            )
                    )
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                if !riotId.isEmpty && !isValid {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text("Le Riot ID doit contenir un # (ex: Faker#KR1)")
                            .font(.caption)
                    }
                    .foregroundStyle(Color(hex: 0xEF4444))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            // Region
            VStack(alignment: .leading, spacing: 8) {
                Text("Region")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Menu {
                    ForEach(Region.allCases) { region in
                        Button {
                            selectedRegion = region
                        } label: {
                            HStack {
                                Text(region.displayName)
                                if selectedRegion == region {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedRegion.displayName)
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(Color(hex: 0x1E293B))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(20)
        .background(Color(hex: 0x1A1F2E).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button {
            saveConfiguration()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                Text(appState.isSetupComplete ? "Mettre a jour" : "Commencer")
                    .font(.headline)
            }
            .foregroundStyle(isValid ? .white : .white.opacity(0.4))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: isValid
                        ? [Color(hex: 0xC89B3C), Color(hex: 0xD4A944)]
                        : [Color(hex: 0x3B4A6B), Color(hex: 0x3B4A6B)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(
                color: isValid ? Color(hex: 0xC89B3C).opacity(0.3) : .clear,
                radius: 10, y: 4
            )
        }
        .disabled(!isValid)
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isValid)
    }

    // MARK: - Info

    private var infoSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.caption2)
                Text("Votre Riot ID est stocke localement sur votre appareil.")
                    .font(.caption)
            }
            .foregroundStyle(.tertiary)

            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption2)
                Text("Utilisez le meme format que sur le client LoL.")
                    .font(.caption)
            }
            .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Actions

    private func saveConfiguration() {
        guard isValid else {
            errorMessage = "Veuillez entrer un Riot ID valide (ex: Faker#KR1)"
            showError = true
            return
        }

        appState.saveProfile(
            riotId: riotId.trimmingCharacters(in: .whitespaces),
            region: selectedRegion
        )
        dismiss()
    }
}

#Preview {
    SetupView()
        .environment(AppState())
}
