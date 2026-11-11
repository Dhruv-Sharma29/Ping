import Foundation

struct IssueAuthor: Decodable {
    let login: String
    let avatarURL: URL

    enum CodingKeys: String, CodingKey {
        case login
        case avatarURL = "avatar_url"
    }

    /// GitHub serves avatars at any size via `s`; the full image is ~460 px, far more than a row needs.
    var smallAvatarURL: URL {
        guard var parts = URLComponents(url: avatarURL, resolvingAgainstBaseURL: false) else { return avatarURL }
        parts.queryItems = (parts.queryItems ?? []) + [URLQueryItem(name: "s", value: "64")]
        return parts.url ?? avatarURL
    }
}
