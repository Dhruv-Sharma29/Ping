import BackgroundTasks
import SwiftData
import UserNotifications

enum Checker {
    // Both must be listed in BGTaskSchedulerPermittedIdentifiers (project.yml).
    static let taskID = "com.dhruvsharma.Ping.refresh"        // short wake-ups, around app use
    static let processingID = "com.dhruvsharma.Ping.process"  // longer slots, usually overnight
    private static var running = false
    static let minimumGap: TimeInterval = 5 * 60
    private static let lastRunKey = "lastCheckRun"

    /// Automatic checks (opening the app, background) skip if one ran recently; `force` is for
    /// things the user asked for (pull to refresh, adding a repo).
    static func shouldRun(lastRun: Date?, now: Date = .now, force: Bool) -> Bool {
        guard !force, let lastRun else { return true }
        return now.timeIntervalSince(lastRun) >= minimumGap
    }

    /// Checks every repo, notifies about new issues, saves the highest number seen.
    /// Returns a one-line summary (used by the background log).
    @discardableResult
    static func run(force: Bool = false) async -> String {
        guard !running else { return "Skipped: a check was already running" } // overlap = double notifications
        let lastRun = UserDefaults.standard.object(forKey: lastRunKey) as? Date
        guard shouldRun(lastRun: lastRun, force: force) else { return "Skipped: checked under 5 minutes before" }
        running = true
        defer { running = false }

        let context = PingApp.container.mainContext
        let repos = (try? context.fetch(FetchDescriptor<Repo>())) ?? []
        let results = await fetchAll(repos.map(\.name))
        var newCount = 0
        var failed = 0
        for repo in repos {
            switch results[repo.name] {
            case .success(let issues):
                let new = GitHub.newIssues(issues, lastSeen: repo.lastSeen)
                for issue in new { await notify(issue, repo: repo.name) }
                newCount += new.count
                repo.lastSeen = max(repo.lastSeen ?? 0, issues.map(\.number).max() ?? 0)
                repo.lastChecked = .now
                repo.error = nil
            case .failure(let error):
                failed += 1
                repo.error = error.localizedDescription
            case nil:
                break // not fetched: iOS ended our time first; checked next run
            }
        }
        try? context.save()
        // Only a finished check counts: one cut short (app closed, background time over) must not
        // hold off the next for 5 minutes.
        guard !Task.isCancelled else { return "Cut short by iOS after \(results.count) of \(repos.count) repos" }
        UserDefaults.standard.set(Date.now, forKey: lastRunKey)
        let issues = newCount == 1 ? "1 new issue" : "\(newCount) new issues"
        return failed == 0 ? "Checked \(repos.count) repos, \(issues)" : "Checked \(repos.count) repos, \(issues), \(failed) failed"
    }

    /// All repos at once rather than one by one: a background wake-up only lasts about 30 seconds.
    private static func fetchAll(_ names: [String]) async -> [String: Result<[Issue], Error>] {
        await withTaskGroup(of: (String, Result<[Issue], Error>).self) { group in
            for name in names {
                group.addTask {
                    do { return (name, .success(try await GitHub.issues(for: name))) } catch { return (name, .failure(error)) }
                }
            }
            var results: [String: Result<[Issue], Error>] = [:]
            for await (name, result) in group {
                if Task.isCancelled, case .failure = result { continue } // cancelled, not a real failure
                results[name] = result
            }
            return results
        }
    }

    /// Ask iOS for both kinds of wake-up. iOS decides the actual times; ours are only the earliest.
    static func scheduleBackgroundChecks() {
        let refresh = BGAppRefreshTaskRequest(identifier: taskID)
        refresh.earliestBeginDate = .now + 15 * 60
        let processing = BGProcessingTaskRequest(identifier: processingID)
        processing.earliestBeginDate = .now + 60 * 60
        processing.requiresNetworkConnectivity = true
        processing.requiresExternalPower = false
        do {
            try BGTaskScheduler.shared.submit(refresh)
            try BGTaskScheduler.shared.submit(processing)
            BackgroundLog.scheduled(earliest: refresh.earliestBeginDate ?? .now)
        } catch {
            BackgroundLog.scheduleFailed(error) // e.g. Background App Refresh off; shown in Account
        }
    }

    /// One background wake-up of either kind: book the next one first (requests are one-shot),
    /// then check, and record what happened.
    static func runInBackground() async {
        scheduleBackgroundChecks()
        let result = await run()
        BackgroundLog.ran(result)
    }

    /// Handler for the processing task, which SwiftUI's `.backgroundTask` doesn't cover.
    /// Registered on the main queue in `PingApp.init`, before launch finishes.
    static func handle(_ task: BGTask) {
        let work = Task { await runInBackground() }
        task.expirationHandler = { work.cancel() }
        Task {
            await work.value
            task.setTaskCompleted(success: !work.isCancelled) // exactly once, after the work ends
        }
    }

    private static func notify(_ issue: Issue, repo: String) async {
        let content = UNMutableNotificationContent()
        content.title = "New issue in \(repo)"
        content.subtitle = "by \(issue.author?.login ?? "unknown") · \(issue.role.label)"
        content.body = "#\(issue.number) \(issue.title)"
        content.sound = .default
        content.userInfo = ["url": issue.htmlURL.absoluteString, "repo": repo] // repo: where a tap opens Ping
        let request = UNNotificationRequest(identifier: "\(repo)#\(issue.number)", content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
