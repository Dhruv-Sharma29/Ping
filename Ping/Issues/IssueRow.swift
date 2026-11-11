import SwiftUI

struct IssueRow: View {
    let issue: Issue
    var repo: String? // shown when the list mixes issues from several repos

    var body: some View {
        Link(destination: issue.htmlURL) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                // Icon shape differs by state too, so state isn't conveyed by color alone.
                Image(systemName: issue.isOpen ? "circle.circle" : "checkmark.circle")
                    .foregroundStyle(issue.isOpen ? Color.green : Color.purple)
                    .accessibilityLabel(issue.isOpen ? "Open" : "Closed")

                VStack(alignment: .leading, spacing: 8) {
                    if let repo {
                        HStack(spacing: 8) {
                            Text(repo)
                                .font(.footnote)
                                .bold()
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            StarCount(repo: repo)
                        }
                    }
                    Text(issue.title)
                        .foregroundStyle(.primary)
                    AuthorLine(author: issue.author, role: issue.role)
                    Text("#\(String(issue.number)) · opened \(issue.createdAt, format: .relative(presentation: .named))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .tint(.primary) // Link would otherwise paint the whole row in the accent color
    }
}
