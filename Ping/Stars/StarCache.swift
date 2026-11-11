import Foundation

/// Star counts saved on the phone with the time they were fetched.
struct StarCache: Codable, Equatable {
    struct Entry: Codable, Equatable {
        let stars: Int
        let fetched: Date
    }

    static let maxAge: TimeInterval = 24 * 60 * 60   // refetch after a day
    static let dropAfter: TimeInterval = 7 * 24 * 60 * 60 // forget repos not seen for a week

    var entries: [String: Entry] = [:]

    func needsFetch(_ repo: String, now: Date = .now) -> Bool {
        guard let entry = entries[repo] else { return true }
        return now.timeIntervalSince(entry.fetched) >= Self.maxAge
    }

    /// Keeps the cache small: Explore shows many one-off repos.
    func pruned(now: Date = .now) -> StarCache {
        StarCache(entries: entries.filter { now.timeIntervalSince($0.value.fetched) < Self.dropAfter })
    }
}
