import Foundation

/// What happened with background checks, saved so the user (and we) can see whether iOS runs them.
/// iOS gives no other way to tell, short of a debugger.
enum BackgroundLog {
    private static let defaults = UserDefaults.standard
    private enum Key {
        static let scheduledFor = "bgScheduledFor"
        static let scheduleError = "bgScheduleError"
        static let lastRun = "bgLastRun"
        static let lastResult = "bgLastResult"
        static let runCount = "bgRunCount"
    }

    static var scheduledFor: Date? { defaults.object(forKey: Key.scheduledFor) as? Date }
    static var scheduleError: String? { defaults.string(forKey: Key.scheduleError) }
    static var lastRun: Date? { defaults.object(forKey: Key.lastRun) as? Date }
    static var lastResult: String? { defaults.string(forKey: Key.lastResult) }
    static var runCount: Int { defaults.integer(forKey: Key.runCount) }

    static func scheduled(earliest: Date) {
        defaults.set(earliest, forKey: Key.scheduledFor)
        defaults.removeObject(forKey: Key.scheduleError)
    }

    static func scheduleFailed(_ error: Error) {
        defaults.set(describe(error), forKey: Key.scheduleError)
    }

    static func ran(_ result: String, at date: Date = .now) {
        defaults.set(date, forKey: Key.lastRun)
        defaults.set(result, forKey: Key.lastResult)
        defaults.set(runCount + 1, forKey: Key.runCount)
    }

    /// BGTaskScheduler's error codes, in words.
    static func describe(_ error: Error) -> String {
        switch (error as NSError).code {
        case 1: "Background App Refresh is off, or not available on this device"
        case 2: "Too many background requests waiting"
        case 3: "Not allowed: the task ID is missing from the app's settings"
        default: error.localizedDescription
        }
    }
}
