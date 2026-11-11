import Foundation

/// An issue together with the repo it came from, for lists that mix repos.
struct RepoIssue: Identifiable {
    let repo: String
    let issue: Issue
    var id: String { "\(repo)#\(issue.number)" }
}
