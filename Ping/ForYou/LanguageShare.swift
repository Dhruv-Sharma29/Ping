import Foundation

/// A language and its share of someone's own public repos.
struct LanguageShare: Identifiable, Equatable {
    let name: String
    let share: Double // 0...1
    var id: String { name }

    /// Ranks languages by how many of the user's own repos use them as their main language.
    /// Forks are skipped (someone else's work), as are repos GitHub couldn't classify.
    // ponytail: counts repos, one request; GitHub's per-repo byte counts would need one request per repo.
    static func top(from repos: [UserRepo], limit: Int = 5) -> [LanguageShare] {
        let languages = repos.filter { !$0.fork }.compactMap(\.language)
        guard !languages.isEmpty else { return [] }
        let counts = Dictionary(languages.map { ($0, 1) }, uniquingKeysWith: +)
        return counts
            .sorted { ($0.value, $1.key) > ($1.value, $0.key) } // most used first, then A–Z
            .prefix(limit)
            .map { LanguageShare(name: $0.key, share: Double($0.value) / Double(languages.count)) }
    }
}
