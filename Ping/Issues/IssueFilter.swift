import Foundation

/// Search text plus filter choices for the all-issues list. Pure logic, so it's unit tested.
struct IssueFilter: Equatable {
    var state = State.all
    var repo: String? // nil = every repo
    var opener = Opener.anyone

    enum State: String, CaseIterable, Identifiable {
        case all, open, closed
        var id: Self { self }
        var label: String { rawValue.capitalized }
    }

    /// Groups of GitHub's eight author roles that are useful to filter by.
    enum Opener: String, CaseIterable, Identifiable {
        case anyone, maintainers, contributors, newcomers, noAssociation
        var id: Self { self }

        var label: String {
            switch self {
            case .anyone: "Anyone"
            case .maintainers: "Maintainers"
            case .contributors: "Contributors"
            case .newcomers: "Newcomers"
            case .noAssociation: "No association"
            }
        }

        func includes(_ role: AuthorRole) -> Bool {
            switch self {
            case .anyone: true
            case .maintainers: role.isMaintainer
            case .contributors: role == .contributor
            case .newcomers: role == .firstTimeContributor || role == .firstTimer
            case .noAssociation: role == .none || role == .mannequin
            }
        }
    }

    var isActive: Bool { self != IssueFilter() }

    /// Button text: "Filter", or the active choices, e.g. "Open · swift · Maintainers".
    var summary: String {
        var parts: [String] = []
        if state != .all { parts.append(state.label) }
        if let repo { parts.append(String(repo.split(separator: "/").last ?? Substring(repo))) }
        if opener != .anyone { parts.append(opener.label) }
        return parts.isEmpty ? "Filter" : parts.joined(separator: " · ")
    }

    /// Matches title, author, repo name or issue number ("123" or "#123").
    func matches(_ item: RepoIssue, search: String) -> Bool {
        let issue = item.issue
        switch state {
        case .all: break
        case .open: guard issue.isOpen else { return false }
        case .closed: guard !issue.isOpen else { return false }
        }
        if let repo, item.repo != repo { return false }
        guard opener.includes(issue.role) else { return false }

        let query = search.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return true }
        let number = query.hasPrefix("#") ? String(query.dropFirst()) : query
        return issue.title.localizedStandardContains(query)
            || (issue.author?.login.localizedStandardContains(query) ?? false)
            || item.repo.localizedStandardContains(query)
            || String(issue.number) == number
    }
}
