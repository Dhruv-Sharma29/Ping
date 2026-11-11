import Foundation

/// An issue from GitHub's search API, which names its repo by API URL instead of `owner/repo`.
struct SearchItem: Decodable {
    let issue: Issue
    let repo: String

    private enum CodingKeys: String, CodingKey {
        case repositoryURL = "repository_url"
    }

    init(from decoder: Decoder) throws {
        issue = try Issue(from: decoder)
        let url = try decoder.container(keyedBy: CodingKeys.self).decode(String.self, forKey: .repositoryURL)
        repo = url.components(separatedBy: "/repos/").last ?? url
    }
}
