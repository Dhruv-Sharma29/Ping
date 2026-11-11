import SwiftUI
import UIKit

/// Account → Background Checks: whether iOS allows them, and what the last one did.
struct BackgroundStatusSection: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var phase
    @State private var refreshStatus = UIApplication.shared.backgroundRefreshStatus
    @State private var lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled

    var body: some View {
        Section {
            LabeledContent("Background App Refresh", value: refreshText)
            if lowPower {
                LabeledContent("Low Power Mode", value: "On (pauses background checks)")
            }
            LabeledContent("Last background check") {
                if let last = BackgroundLog.lastRun {
                    Text(last, format: .relative(presentation: .named))
                } else {
                    Text("Not yet")
                }
            }
            if let result = BackgroundLog.lastResult {
                Text(result)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if let error = BackgroundLog.scheduleError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            if refreshStatus == .denied {
                Button("Turn On in Settings", action: openSettings)
            }
        } header: {
            Text("Background Checks")
        } footer: {
            Text("iOS decides when Ping runs in the background: often every 30 minutes to a few hours, more if you open Ping often. It never runs after you swipe Ping away in the app switcher, until you open it again.")
        }
        .onChange(of: phase) { refresh() }
        .onAppear(perform: refresh)
    }

    private var refreshText: String {
        switch refreshStatus {
        case .available: "On"
        case .denied: "Off"
        case .restricted: "Restricted on this iPhone"
        @unknown default: "Unknown"
        }
    }

    private func refresh() {
        refreshStatus = UIApplication.shared.backgroundRefreshStatus
        lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}
