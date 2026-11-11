import SwiftUI

/// Every issue of one repo, newest first, loading older pages as you scroll.
struct IssueListView: View {
    let repo: String
    @State private var feed = IssueFeed()

    var body: some View {
        List {
            ForEach(feed.visible) { item in
                IssueRow(issue: item.issue)
            }
            if feed.hasMore, feed.didLoad {
                LoadMoreRow(isLoading: feed.isLoading, action: loadMore)
            }
        }
        .overlay {
            if let error = feed.errors[repo], feed.visible.isEmpty {
                ContentUnavailableView(
                    "Couldn't Load Issues",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if !feed.didLoad {
                ProgressView()
            } else if feed.visible.isEmpty, !feed.hasMore {
                ContentUnavailableView(
                    "No Issues",
                    systemImage: "checkmark.circle",
                    description: Text("Nobody has opened an issue in this repo yet.")
                )
            }
        }
        .navigationTitle(repo)
        .navigationBarTitleDisplayMode(.inline)
        .task { await feed.reload(repos: [repo]) }
        .refreshable { await feed.reload(repos: [repo]) }
    }

    private func loadMore() {
        Task { await feed.loadMore() }
    }
}
