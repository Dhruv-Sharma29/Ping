import SwiftUI
import UIKit

/// Shown on Repos when Background App Refresh is off: Ping then only checks while open.
struct BackgroundOffSection: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Label("Background Checks Are Off", systemImage: "moon.zzz.fill")
                    .font(.headline)
                Text("Ping can only look for new issues while it's open. Turn on Background App Refresh for Ping.")
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
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}
