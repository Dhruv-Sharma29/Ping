import UIKit
import UserNotifications

/// Shows banners while the app is open, and opens the issue when a notification is tapped.
/// UIKit is used here because the delegate lives outside any SwiftUI view (no openURL environment).
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let link = response.notification.request.content.userInfo["url"] as? String,
              let url = URL(string: link) else { return }
        await MainActor.run { UIApplication.shared.open(url) }
    }
}
