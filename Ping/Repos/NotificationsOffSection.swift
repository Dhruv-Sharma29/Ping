import SwiftUI

/// Shown when the user denied notifications: Ping's whole job depends on them.
struct NotificationsOffSection: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Label("Notifications Are Off", systemImage: "bell.slash.fill")
                    .font(.headline)
                Text("Ping can't alert you about new issues until you turn them on.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Open Settings", action: openSettings)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
            }
            .padding(.vertical, 8)
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        openURL(url)
    }
}
