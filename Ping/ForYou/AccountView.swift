import SwiftUI

/// Who the recommendations are for: GitHub username and the languages to suggest issues in.
/// Everything here is saved on the phone and survives relaunches.
struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(StorageKey.detectedLanguages) private var detectedRaw = ""
    @State private var isEditing = false
    @AppStorage(StorageKey.handle) private var handle = ""
    @AppStorage(StorageKey.preferredLanguages) private var preferredRaw = ""
    @AppStorage(StorageKey.suggestionFilter) private var filter = SuggestionFilter()
    @AppStorage(StorageKey.exploreLanguage) private var exploreLanguage = ""
    @AppStorage(StorageKey.hasToken) private var hasToken = false

    private static let maxLanguages = 3

    private var chosen: [String] { preferredRaw.split(separator: "\n").map(String.init) }

    /// The user's own languages (saved by For You), listed before the popular ones.
    private var detected: [String] { detectedRaw.split(separator: "\n").map(String.init) }

    private var choices: [String] {
        detected + LanguageMenu.popular.filter { !detected.contains($0) }
    }

    var body: some View {
        NavigationStack {
            Form {
                if isEditing {
                    HandleSection(handle: $handle, onCancel: stopEditing)
                } else {
                    ProfileCard(handle: handle, onEdit: startEditing)
                }

                Section {
                    ForEach(choices, id: \.self) { language in
                        LanguageChoiceRow(
                            language: language,
                            rank: chosen.firstIndex(of: language).map { $0 + 1 },
                            isDisabled: !chosen.contains(language) && chosen.count >= Self.maxLanguages,
                            action: { toggle(language) }
                        )
                    }
                } header: {
                    Text("Languages for Suggestions")
                } footer: {
                    Text(chosen.isEmpty
                         ? "None chosen, so Ping uses your top 3 languages from GitHub. Pick up to 3 to choose yourself."
                         : "Ping suggests issues in these, in this order. Tap a language again to remove it.")
                }

                TokenSection()

                BackgroundStatusSection()

                Section {
                    Button("Forget Account", role: .destructive, action: forget)
                        .disabled(handle.isEmpty && chosen.isEmpty && !hasToken)
                } footer: {
                    Text("Removes your username, token, languages and recommendation filters from this iPhone. Watched repos stay.")
                }
            }
            .onChange(of: handle) { isEditing = false } // saved a new username
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: close)
                }
            }
        }
    }

    private func startEditing() {
        isEditing = true
    }

    private func stopEditing() {
        isEditing = false
    }

    private func toggle(_ language: String) {
        var list = chosen
        if let index = list.firstIndex(of: language) {
            list.remove(at: index)
        } else if list.count < Self.maxLanguages {
            list.append(language)
        }
        preferredRaw = list.joined(separator: "\n")
    }

    private func forget() {
        handle = ""
        preferredRaw = ""
        detectedRaw = ""
        filter = SuggestionFilter()
        exploreLanguage = ""
        TokenStore.delete()
        RateLimit.clear()
    }

    private func close() {
        dismiss()
    }
}
