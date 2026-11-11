import Foundation

/// One page of a repo's issue list from GitHub.
struct IssuePage {
    let issues: [Issue]     // pull requests already removed
    let oldest: Date?       // creation date of the page's last item (issue or PR)
    let hasMore: Bool       // a full page: there may be older ones
}
