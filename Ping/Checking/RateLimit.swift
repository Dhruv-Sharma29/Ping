import Foundation

/// Remembers when GitHub's rate limit resets and blocks requests until then, so Ping waits instead of
/// sending requests that are certain to fail. Search has its own limit, so it is tracked separately.
enum RateLimit {
    private static var resets: [String: Date] = [:] // resource ("core" / "search") → reset time

    static func resource(for path: String) -> String {
        path.hasPrefix("search/") ? "search" : "core"
    }

    /// The reset time if this resource is still blocked, nil if requests may go out.
    static func blockedUntil(_ resource: String, now: Date = .now) -> Date? {
        guard let reset = resets[resource], reset > now else { return nil }
        return reset
    }

    static func block(_ resource: String, until reset: Date) {
        resets[resource] = reset
    }

    /// A new or removed token changes which limit applies, so earlier blocks no longer hold.
    static func clear() {
        resets = [:]
    }

    /// When a refused request may be retried, from GitHub's headers: `retry-after` (seconds, for
    /// secondary limits) or, once `x-ratelimit-remaining` is 0, `x-ratelimit-reset` (Unix time).
    /// nil means the 403 wasn't a rate limit.
    static func resetDate(header: (String) -> String?, now: Date = .now) -> Date? {
        if let seconds = header("retry-after").flatMap(Double.init) {
            return now.addingTimeInterval(seconds)
        }
        if header("x-ratelimit-remaining") == "0", let epoch = header("x-ratelimit-reset").flatMap(Double.init) {
            return Date(timeIntervalSince1970: epoch)
        }
        return nil
    }

    static func message(until reset: Date) -> String {
        "GitHub limit reached. Resets at \(reset.formatted(date: .omitted, time: .shortened))."
    }
}
