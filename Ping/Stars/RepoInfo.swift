import Foundation

/// The one field of GET /repos/{owner}/{repo} that Ping shows.
struct RepoInfo: Decodable {
    let stargazersCount: Int

    enum CodingKeys: String, CodingKey {
        case stargazersCount = "stargazers_count"
    }
}
