import Foundation
import Observation

/// Carries a tapped notification's repo from the notification delegate into the UI, which opens
/// that repo's issue list inside Ping.
@Observable final class NotificationRouter {
    static let shared = NotificationRouter()

    /// Set when a notification is tapped; cleared by the repo list once it has navigated.
    var pendingRepo: String?

    /// "owner/repo" from a notification: the `repo` key, or for notifications sent before it
    /// existed, the path of the issue link (`https://github.com/owner/repo/issues/12`).
    nonisolated static func repo(from userInfo: [AnyHashable: Any]) -> String? { // pure; called off the main actor
        if let repo = userInfo["repo"] as? String, !repo.isEmpty { return repo }
        guard let link = userInfo["url"] as? String, let url = URL(string: link), url.host() == "github.com" else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }
        return parts.count >= 2 ? "\(parts[0])/\(parts[1])" : nil
    }
}
