import Foundation

extension GitHub {
    /// Where to create a fine-grained token (no permissions needed for public data).
    static let newTokenURL = URL(string: "https://github.com/settings/personal-access-tokens/new")!

    /// Asks GitHub whether a token works, before saving it. Returns the hourly request limit it gives.
    /// /rate_limit doesn't count against the limit.
    static func checkToken(_ token: String) async throws -> Int {
        var request = URLRequest(url: URL(string: "https://api.github.com/rate_limit")!)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        switch (response as? HTTPURLResponse)?.statusCode ?? 0 {
        case 200: return try JSONDecoder().decode(RateLimitResponse.self, from: data).resources.core.limit
        case 401: throw GitHubError("GitHub didn't accept this token. Check you copied all of it.")
        case let code: throw GitHubError("Couldn't check the token (GitHub error \(code)).")
        }
    }

    /// A pasted token with spaces or line breaks trimmed; nil if it can't be one.
    static func cleanToken(_ input: String) -> String? {
        let token = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard token.count >= 20, !token.contains(where: \.isWhitespace) else { return nil }
        return token
    }
}
