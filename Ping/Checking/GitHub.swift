import Foundation

enum GitHub {
    /// "owner/repo" or a github.com link -> "owner/repo"; nil if it isn't one.
    /// Validated because it goes into the API URL path.
    static func normalize(_ input: String) -> String? {
        let s = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = /^(?:https?:\/\/)?(?:www\.)?(?:github\.com\/)?([A-Za-z0-9-]+)\/([A-Za-z0-9._-]+?)(?:\.git)?\/?$/
        guard let m = try? pattern.wholeMatch(in: s), m.2 != ".", m.2 != ".." else { return nil }
        return "\(m.1)/\(m.2)"
    }

    static let pageSize = 100 // GitHub's maximum

    /// Latest issues (newest first), pull requests removed: the first page only.
    // ponytail: the notification check reads one page (newest 100 issues+PRs); >100 created between checks drops the extras. The Issues tab pages through everything.
    static func issues(for repo: String) async throws -> [Issue] {
        try await page(for: repo, number: 1).issues
    }

    /// One page of a repo's issues, newest first. Page 1 is the newest.
    static func page(for repo: String, number: Int) async throws -> IssuePage {
        let data = try await get("repos/\(repo)/issues", query: [
            "state": "all", "sort": "created", "direction": "desc",
            "per_page": String(pageSize), "page": String(number),
        ], notFound: "Repo not found, or it's private")
        return try decodePage(data, pageSize: pageSize)
    }

    /// GET from the REST API, mapping failures to messages a person can act on.
    static func get(_ path: String, query: [String: String], notFound: String) async throws -> Data {
        guard var url = URLComponents(string: "https://api.github.com/\(path)") else {
            throw GitHubError("Invalid request")
        }
        url.queryItems = query.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let requestURL = url.url else { throw GitHubError("Invalid request") }
        let resource = RateLimit.resource(for: path)
        if let reset = RateLimit.blockedUntil(resource) { // don't spend a request that will be refused
            throw GitHubError(RateLimit.message(until: reset))
        }
        var request = URLRequest(url: requestURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        if let token = TokenStore.token { // header only: never in the URL, never logged
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        let http = response as? HTTPURLResponse
        switch http?.statusCode ?? 0 {
        case 200: return data
        case 401: throw GitHubError("GitHub didn't accept your token. Replace or remove it in Account.")
        case 404: throw GitHubError(notFound)
        case 403, 429:
            if let reset = RateLimit.resetDate(header: { http?.value(forHTTPHeaderField: $0) }) {
                RateLimit.block(resource, until: reset)
                throw GitHubError(RateLimit.message(until: reset))
            }
            throw GitHubError(http?.statusCode == 429 ? "GitHub rate limit hit. Ping will retry later." : "GitHub refused the request (403)")
        case let code: throw GitHubError("GitHub error \(code)")
        }
    }

    /// A full page means there may be more. `oldest` counts pull requests too: everything on later
    /// pages is older than this page's last item, issue or not.
    static func decodePage(_ data: Data, pageSize: Int) throws -> IssuePage {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let all = try decoder.decode([Issue].self, from: data)
        return IssuePage(
            issues: all.filter { $0.pullRequest == nil },
            oldest: all.last?.createdAt,
            hasMore: all.count == pageSize
        )
    }

    static func decode(_ data: Data) throws -> [Issue] {
        try decodePage(data, pageSize: .max).issues
    }

    /// Issues to notify about. First check (lastSeen == nil) only seeds, so old issues don't spam you.
    static func newIssues(_ issues: [Issue], lastSeen: Int?) -> [Issue] {
        guard let lastSeen else { return [] }
        return issues.filter { $0.number > lastSeen }
    }
}
