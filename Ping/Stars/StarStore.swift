import Foundation
import Observation

/// Star counts per repo, saved on the phone and refetched only when older than a day.
/// A stale count is still shown while the new one loads.
@Observable final class StarStore {
    static let shared = StarStore()
    private static let key = "starCache"

    private var cache: StarCache
    @ObservationIgnored private var inFlight: Set<String> = []

    init() {
        let saved = UserDefaults.standard.data(forKey: Self.key)
            .flatMap { try? JSONDecoder().decode(StarCache.self, from: $0) }
        cache = (saved ?? StarCache()).pruned()
    }

    func stars(for repo: String) -> Int? {
        cache.entries[repo]?.stars
    }

    func load(_ repo: String) async {
        guard cache.needsFetch(repo), inFlight.insert(repo).inserted else { return }
        defer { inFlight.remove(repo) } // a failed fetch (e.g. rate limit) may retry later
        guard let data = try? await GitHub.get("repos/\(repo)", query: [:], notFound: "Repo not found"),
              let info = try? JSONDecoder().decode(RepoInfo.self, from: data)
        else { return }
        cache.entries[repo] = .init(stars: info.stargazersCount, fetched: .now)
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}
