import SwiftUI

/// The newest open issues across all of GitHub, by language and keyword.
struct ExploreView: View {
    @AppStorage(StorageKey.handle) private var handle = ""
    @AppStorage(StorageKey.exploreLanguage) private var savedLanguage = "" // remembered between launches
    @State private var text = ""
    @State private var submitted = ""
    @State private var items: [RepoIssue] = []
    @State private var page = 0
    @State private var hasMore = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var yourLanguages: [String] = []

    private static let perPage = 30

    private var language: Binding<String?> {
        Binding { savedLanguage.isEmpty ? nil : savedLanguage } set: { savedLanguage = $0 ?? "" }
    }

    private var query: String {
        GitHub.exploreQuery(language: savedLanguage.isEmpty ? nil : savedLanguage, text: submitted)
    }

    var body: some View {
        NavigationStack {
            List {
                if !items.isEmpty {
                    Section {
                        ForEach(items) { item in
                            IssueRow(issue: item.issue, repo: item.repo)
                        }
                        if hasMore, errorMessage == nil {
                            LoadMoreRow(isLoading: isLoading, action: loadMore)
                        }
                    } header: {
                        Text(savedLanguage.isEmpty ? "Newest issues on GitHub" : "Newest \(savedLanguage) issues")
                    } footer: {
                        if let errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle")
                        }
                    }
                }
            }
            .overlay {
                if items.isEmpty, let errorMessage {
                    ContentUnavailableView("Couldn't Load Issues", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
                } else if items.isEmpty, isLoading {
                    ProgressView()
                } else if items.isEmpty, !hasMore {
                    ContentUnavailableView.search(text: submitted)
                }
            }
            .navigationTitle("Explore")
            .searchable(text: $text, prompt: "Keywords, then Search")
            .onSubmit(of: .search) { submitted = text } // one request per search, not per keystroke
            .onChange(of: text) { if text.isEmpty { submitted = "" } }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    LanguageMenu(selection: language, yours: yourLanguages)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileButton()
                }
            }
            .task(id: query) { await reload() }
            .task(id: handle) { await loadYourLanguages() }
            .refreshable { await reload() }
        }
    }

    private func reload() async {
        items = []
        page = 0
        hasMore = true
        errorMessage = nil
        await fetch(page: 1)
    }

    private func loadMore() {
        guard !isLoading, hasMore, errorMessage == nil else { return }
        Task { await fetch(page: page + 1) }
    }

    private func fetch(page next: Int) async {
        let current = query
        isLoading = true
        defer { if current == query { isLoading = false } }
        do {
            let result = try await GitHub.searchIssues(query: current, page: next, perPage: Self.perPage, sort: "created")
            guard current == query, next == page + 1 else { return } // the search changed meanwhile
            let seen = Set(items.map(\.id))
            items += result.items.filter { !seen.contains($0.id) }
            page = next
            hasMore = result.hasMore
        } catch {
            guard current == query else { return }
            errorMessage = error.localizedDescription
        }
    }

    /// Puts the user's own languages at the top of the picker (one request, only with a saved username).
    private func loadYourLanguages() async {
        guard !handle.isEmpty, let repos = try? await GitHub.repos(of: handle) else { return }
        yourLanguages = LanguageShare.top(from: repos).map(\.name)
    }
}

#Preview {
    ExploreView()
}
