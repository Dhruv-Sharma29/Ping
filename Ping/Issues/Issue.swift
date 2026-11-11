import Foundation

struct Issue: Decodable, Identifiable {
    let number: Int
    let title: String
    let state: String
    let htmlURL: URL
    let createdAt: Date
    let author: IssueAuthor? // optional so one odd record can't break the whole list
    let role: AuthorRole
    let pullRequest: PullRequest? // only present when the "issue" is really a PR
    var id: Int { number }
    var isOpen: Bool { state == "open" }

    struct PullRequest: Decodable {}

    enum CodingKeys: String, CodingKey {
        case number, title, state
        case htmlURL = "html_url"
        case createdAt = "created_at"
        case author = "user"
        case role = "author_association"
        case pullRequest = "pull_request"
    }
}
