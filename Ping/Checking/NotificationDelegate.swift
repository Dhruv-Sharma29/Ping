import UserNotifications

/// Shows banners while the app is open, and opens Ping on the repo's issue list when a
/// notification is tapped (the issue is at the top; tapping it there opens it on GitHub).
///
/// Completion-handler methods on the main actor, not the `async` versions: an async delegate
/// method finishes on a background thread and calls iOS's completion handler from there, and
/// UIKit then stops the app (crash reports from the iPhone 15, 2026-11-11 and 2026-11-12).
/// The SDK declares this delegate main-actor; these methods stay on it.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if let repo = NotificationRouter.repo(from: response.notification.request.content.userInfo) {
            NotificationRouter.shared.pendingRepo = repo
        }
        completionHandler()
    }
}
