import UserNotifications

/// Shows banners while the app is open, and opens Ping on the repo's issue list when a
/// notification is tapped (the issue is at the top; tapping it there opens it on GitHub).
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let repo = NotificationRouter.repo(from: response.notification.request.content.userInfo) else { return }
        await MainActor.run { NotificationRouter.shared.pendingRepo = repo }
    }
}
