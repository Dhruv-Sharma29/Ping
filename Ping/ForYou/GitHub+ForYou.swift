import Foundation

extension GitHub {
    /// "name", "@name" or a github.com profile link -> "name"; nil if it can't be a GitHub username
    /// (letters, digits and single inner hyphens, at most 39 characters).
    static func normalizeHandle(_ input: String) -> String? {
        let s = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = /^(?:https?:\/\/)?(?:www\.)?(?:github\.com\/)?@?([A-Za-z0-9](?:[A-Za-z0-9]|-(?=[A-Za-z0-9])){0,38})\/?$/
        return (try? pattern.wholeMatch(in: s)).map { String($0.1) }
    }

    /// The user's public repos they own (one page of up to 100, most recently pushed first).
    static func repos(of handle: String) async throws -> [UserRepo] {
        let data = try await get("users/\(handle)/repos", query: [
            "type": "owner", "sort": "pushed", "per_page": "100",
        ], notFound: "No GitHub user called \(handle)")
        return try JSONDecoder().decode([UserRepo].self, from: data)
    }

    /// Search qualifiers for recommended issues in one language: open, matching the filter's label,
    /// assignment, comment count and age, and not in the user's own repos.
    static func suggestionQuery(language: String, excluding handle: String, since: Date,
                                filter: SuggestionFilter = SuggestionFilter()) -> String {
        var parts = ["is:issue", "is:open"]
        if filter.unassignedOnly { parts.append("no:assignee") }
        if filter.label != .any { parts.append(#"label:"\#(filter.label.rawValue)""#) }
        parts.append(#"language:"\#(language)""#)
        if let max = filter.maxComments { parts.append("comments:<\(max)") }
        parts.append("created:>=\(since.formatted(.iso8601.year().month().day()))")
        parts.append("-user:\(handle)")
        return parts.joined(separator: " ")
    }

    /// Up to 10 suggestions for one language, GitHub's best matches first.
    /// The search API allows 10 unauthenticated requests a minute.
    static func suggestions(language: String, for handle: String, filter: SuggestionFilter) async throws -> [RepoIssue] {
        let since = Date.now.addingTimeInterval(-Double(filter.days) * 24 * 60 * 60)
        return try await searchIssues(
            query: suggestionQuery(language: language, excluding: handle, since: since, filter: filter),
            page: 1, perPage: 10, sort: nil
        ).items
    }

    /// One page of GitHub's issue search. `sort: nil` means GitHub's best match.
    /// Unauthenticated, the search API allows 10 requests a minute.
    static func searchIssues(query: String, page: Int, perPage: Int, sort: String?) async throws -> (items: [RepoIssue], hasMore: Bool) {
        var params = ["q": query, "page": String(page), "per_page": String(perPage)]
        if let sort { params["sort"] = sort; params["order"] = "desc" }
        let data = try await get("search/issues", query: params, notFound: "Search unavailable")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let results = try decoder.decode(SearchResults.self, from: data)
        return (results.items.map { RepoIssue(repo: $0.repo, issue: $0.issue) }, results.hasMore(page: page, perPage: perPage))
    }

    /// Newest open issues on all of GitHub, optionally in one language and matching keywords.
    static func exploreQuery(language: String?, text: String) -> String {
        var parts = ["is:issue", "is:open"]
        if let language { parts.append(#"language:"\#(language)""#) }
        let words = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !words.isEmpty { parts.append(words) }
        return parts.joined(separator: " ")
    }
}
