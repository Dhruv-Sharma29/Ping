import BackgroundTasks
import SwiftData
import SwiftUI
import UserNotifications

@main
struct PingApp: App {
    static let container: ModelContainer = {
        do {
            return try ModelContainer(for: Repo.self)
        } catch {
            fatalError("Couldn't open Ping's database: \(error)")
        }
    }()

    private static let notifications = NotificationDelegate()
    @Environment(\.scenePhase) private var phase

    init() {
        UNUserNotificationCenter.current().delegate = Self.notifications
        // Must happen before launch finishes: iOS may launch Ping straight into the background.
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Checker.processingID, using: .main) { task in
            MainActor.assumeIsolated { Checker.handle(task) }
        }
        // Not here: SwiftUI registers the .appRefresh handler after init, and submitting a request
        // before its handler exists makes iOS stop the app.
    }

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(Self.container)
            .onChange(of: phase, initial: true) { // book wake-ups on every launch and when leaving
                if phase != .inactive { Checker.scheduleBackgroundChecks() }
            }
            .backgroundTask(.appRefresh(Checker.taskID)) {
                await Checker.runInBackground()
            }
    }
}
