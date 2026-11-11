import SwiftData
import SwiftUI

/// Every issue from every watched repo, notified or not, with search and filters.
/// Older issues load page by page as you scroll, back to each repo's first issue.
struct AllIssuesView: View {
    @Query(sort: \Repo.name) private var repos: [Repo]
    @State private var feed = IssueFeed()
    @State private var search = ""
    @State private var filter = IssueFilter()

    private var shown: [RepoIssue] {
        feed.visible.filter { filter.matches($0, search: search) }
    }

    var body: some View {
        NavigationStack {
            List {
                if feed.didLoad, !repos.isEmpty {
                    Section {
                        ForEach(shown) { item in
                            IssueRow(issue: item.issue, repo: item.repo)
                        }
                        if feed.hasMore {
                            LoadMoreRow(isLoading: feed.isLoading, action: loadMore)
                        }
                    } header: {
                        if feed.hasMore {
                            Text("\(shown.count) shown · older issues load as you scroll")
                        } else {
                            Text("^[\(shown.count) issue](inflect: true)")
                        }
                    } footer: {
                        if !feed.failedRepos.isEmpty {
                            Label("Couldn't load \(feed.failedRepos.formatted()). Pull to retry.", systemImage: "exclamationmark.triangle")
                        }
                    }
                }
            }
            .overlay {
                if repos.isEmpty {
                    ContentUnavailableView(
                        "No Repos Yet",
                        systemImage: "tray",
                        description: Text("Add repos in the Repos tab to see their issues here.")
                    )
                } else if !feed.didLoad {
                    ProgressView()
                } else if shown.isEmpty, !feed.hasMore, !search.isEmpty {
                    ContentUnavailableView.search
                } else if shown.isEmpty, !feed.hasMore {
                    ContentUnavailableView {
                        Label("No Matching Issues", systemImage: "line.3.horizontal.decrease.circle")
                    } description: {
                        Text("No issues match these filters.")
                    } actions: {
                        if filter.isActive {
                            Button("Clear Filters", action: clearFilters)
                        }
                    }
                }
            }
            .navigationTitle("Issues")
            .searchable(text: $search, prompt: "Title, author, repo or #number")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    IssueFilterMenu(filter: $filter, repoNames: repos.map(\.name))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileButton()
                }
            }
            .refreshable { await reload() }
            .task(id: repos.map(\.name)) { await reload() }
        }
    }

    private func reload() async {
        let names = repos.map(\.name)
        await feed.reload(repos: names)
        if let repo = filter.repo, !names.contains(repo) { filter.repo = nil } // repo was removed
    }

    private func loadMore() {
        Task { await feed.loadMore() }
    }

    private func clearFilters() {
        filter = IssueFilter()
    }
}

#Preview {
    AllIssuesView()
        .modelContainer(for: Repo.self, inMemory: true)
}
