import SwiftUI

/// Recommended open issues in the languages the user writes most (or picked in Account),
/// narrowed by the saved recommendation filters.
struct ForYouView: View {
    @AppStorage(StorageKey.handle) private var handle = ""
    @AppStorage(StorageKey.preferredLanguages) private var preferredRaw = ""
    @AppStorage(StorageKey.suggestionFilter) private var filter = SuggestionFilter()
    @AppStorage(StorageKey.detectedLanguages) private var detectedRaw = ""
    @State private var languages: [LanguageShare]?
    @State private var suggestions: [String: [RepoIssue]] = [:]
    @State private var suggestionErrors: [String: String] = [:]
    @State private var profileError: String?
    @State private var isShowingAccount = false

    private var preferred: [String] { preferredRaw.split(separator: "\n").map(String.init) }

    /// Up to 3: the search API allows 10 unauthenticated requests a minute.
    private var suggestedLanguages: [String] {
        preferred.isEmpty ? (languages ?? []).prefix(3).map(\.name) : Array(preferred.prefix(3))
    }

    /// Suggestions reload when any input changes.
    private var suggestionKey: String {
        [handle, suggestedLanguages.joined(separator: ","), filter.rawValue].joined(separator: "|")
    }

    var body: some View {
        NavigationStack {
            List {
                if let profileError, !suggestedLanguages.isEmpty {
                    Section {
                        Label("Couldn't load your top languages: \(profileError)", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.secondary)
                    }
                }

                if let languages, !languages.isEmpty {
                    Section {
                        ForEach(Array(languages.enumerated()), id: \.element.id) { index, language in
                            LanguageRow(rank: index + 1, language: language)
                        }
                    } header: {
                        Text("\(handle)'s Top Languages")
                    } footer: {
                        if preferred.isEmpty {
                            Text("Share of your public repos by main language. Forks aren't counted.")
                        } else {
                            Text("Suggestions use the languages you picked in Account: \(preferred.formatted()).")
                        }
                    }
                }

                ForEach(suggestedLanguages, id: \.self) { language in
                    SuggestionSection(
                        title: "\(filter.label.sectionTitle) · \(language)",
                        items: suggestions[language],
                        error: suggestionErrors[language]
                    )
                }
            }
            .overlay {
                if handle.isEmpty {
                    ContentUnavailableView {
                        Label("Get Suggested Issues", systemImage: "sparkles")
                    } description: {
                        Text("Add your GitHub username. Ping finds your top languages and recommends open issues in them.")
                    } actions: {
                        Button("Set Up Account", action: showAccount)
                            .buttonStyle(.borderedProminent)
                    }
                } else if let profileError, suggestedLanguages.isEmpty { // picked languages still work without the profile
                    ContentUnavailableView("Couldn't Load Your Profile", systemImage: "exclamationmark.triangle", description: Text(profileError))
                } else if languages == nil, suggestedLanguages.isEmpty {
                    ProgressView()
                }
            }
            .navigationTitle("For You")
            .toolbar {
                if !handle.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        SuggestionFilterMenu(filter: $filter)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileButton()
                }
            }
            .sheet(isPresented: $isShowingAccount) { // for the "Set Up Account" button
                AccountView()
            }
            .task(id: handle) { await loadLanguages() }
            .task(id: suggestionKey) { await loadSuggestions() }
            .refreshable {
                await loadLanguages()
                await loadSuggestions()
            }
        }
    }

    private func showAccount() {
        isShowingAccount = true
    }

    private func loadLanguages() async {
        languages = nil
        profileError = nil
        guard !handle.isEmpty else { return }
        do {
            let top = LanguageShare.top(from: try await GitHub.repos(of: handle))
            languages = top
            detectedRaw = top.map(\.name).joined(separator: "\n") // so Account can list them from any tab
        } catch {
            profileError = error.localizedDescription
        }
    }

    private func loadSuggestions() async {
        suggestions = [:]
        suggestionErrors = [:]
        guard !handle.isEmpty else { return }
        for language in suggestedLanguages { // one at a time, to stay well inside the search limit
            do {
                suggestions[language] = try await GitHub.suggestions(language: language, for: handle, filter: filter)
            } catch {
                if Task.isCancelled { return } // inputs changed; a newer load is running
                suggestionErrors[language] = error.localizedDescription
            }
        }
    }
}

#Preview {
    ForYouView()
}
