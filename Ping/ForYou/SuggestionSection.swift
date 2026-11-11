import SwiftUI

/// One language's recommended issues: loading, error, empty or the list.
struct SuggestionSection: View {
    let title: String
    let items: [RepoIssue]?
    let error: String?

    var body: some View {
        Section {
            if let error {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
            } else if let items {
                if items.isEmpty {
                    Text("Nothing matches. Try loosening the filters.")
                        .foregroundStyle(.secondary)
                }
                ForEach(items) { item in
                    IssueRow(issue: item.issue, repo: item.repo)
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        } header: {
            Text(title)
        }
    }
}
