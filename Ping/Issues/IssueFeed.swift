import Foundation
import Observation

/// Merges the issue lists of several repos into one newest-first list and pages through all of them.
///
/// Each repo is paged separately. `visible` only shows issues that can't be preceded by one still on
/// GitHub, so loading older pages only ever appends to the bottom of the list.
@Observable final class IssueFeed {
    typealias Fetch = @Sendable (_ repo: String, _ page: Int) async throws -> IssuePage

    private struct Source {
        var nextPage = 1
        var hasMore = true
        var oldest: Date?
    }

    private let fetch: Fetch
    private var sources: [String: Source] = [:]
    private var generation = 0 // a reload makes in-flight older pages stale
    private(set) var loaded: [RepoIssue] = []
    private(set) var errors: [String: String] = [:] // repo → message
    private(set) var isLoading = false
    private(set) var didLoad = false

    init(fetch: @escaping Fetch = { try await GitHub.page(for: $0, number: $1) }) {
        self.fetch = fetch
    }

    var failedRepos: [String] { errors.keys.sorted() }
    var hasMore: Bool { sources.values.contains(where: \.hasMore) }

    /// Loaded issues no newer than the cutoff: the most recent "oldest loaded" date among repos with
    /// more pages. Anything older might still have an unloaded issue from another repo above it.
    var visible: [RepoIssue] {
        guard let cutoff = sources.values.filter(\.hasMore).compactMap(\.oldest).max() else { return loaded }
        return loaded.filter { $0.issue.createdAt >= cutoff }
    }

    /// Starts over with page 1 of every repo, fetched in parallel.
    func reload(repos: [String]) async {
        generation += 1
        isLoading = true
        defer { isLoading = false }
        let fetch = self.fetch
        var results: [(String, Result<IssuePage, Error>)] = []
        await withTaskGroup(of: (String, Result<IssuePage, Error>).self) { group in
            for repo in repos {
                group.addTask {
                    do { return (repo, .success(try await fetch(repo, 1))) } catch { return (repo, .failure(error)) }
                }
            }
            for await result in group { results.append(result) }
        }
        sources = [:]
        loaded = []
        errors = [:]
        for (repo, result) in results {
            switch result {
            case .success(let page): apply(page, repo: repo, number: 1)
            case .failure(let error): errors[repo] = error.localizedDescription
            }
        }
        didLoad = true
    }

    /// Loads the next page of whichever repo is holding the list back. Stops as soon as new issues
    /// become visible, after 3 requests at most (a page can be all pull requests).
    func loadMore() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        let startGeneration = generation
        let before = visible.count
        for _ in 0..<3 {
            guard let next = sources.filter(\.value.hasMore)
                .max(by: { ($0.value.oldest ?? .distantPast) < ($1.value.oldest ?? .distantPast) })
            else { return }
            let result: Result<IssuePage, Error>
            do { result = .success(try await fetch(next.key, next.value.nextPage)) } catch { result = .failure(error) }
            guard generation == startGeneration else { return } // reloaded meanwhile
            switch result {
            case .success(let page): apply(page, repo: next.key, number: next.value.nextPage)
            case .failure(let error):
                sources[next.key]?.hasMore = false // stop retrying it; pull to refresh starts over
                errors[next.key] = error.localizedDescription
            }
            if visible.count > before { return }
        }
    }

    private func apply(_ page: IssuePage, repo: String, number: Int) {
        var source = sources[repo] ?? Source()
        source.nextPage = number + 1
        source.hasMore = page.hasMore
        source.oldest = page.oldest ?? source.oldest
        sources[repo] = source
        // New issues opened while paging shift GitHub's pages, so a page can repeat earlier items.
        let seen = Set(loaded.map(\.id))
        loaded += page.issues.map { RepoIssue(repo: repo, issue: $0) }.filter { !seen.contains($0.id) }
        loaded.sort { ($0.issue.createdAt, $0.id) > ($1.issue.createdAt, $1.id) }
    }
}
