# Ping — Plan

iPhone app: you pick GitHub repos, Ping notifies you when a new issue is opened.

## The hard constraint: iOS doesn't let apps poll on a timer
An iPhone app can't run "every 5 minutes" in the background. So "notify me when a
new issue is raised" has two possible designs, with a real trade-off:

### Option A — App only (free, delayed)
```
iPhone: SwiftUI app ──(BGAppRefreshTask, when iOS allows)──> GitHub API
        └── local notification if new issues found
```
- iOS decides when the background check runs: sometimes every ~15–30 min, sometimes
  hours apart, and **never** if you swipe the app away. Also checks on app open.
- No server, no cost. Runs on your own iPhone with a free Apple ID
  (re-install from Xcode every 7 days, a free-account limit).
- Good for: learning SwiftUI + GitHub API; "within a few hours" is acceptable.

### Option B — App + small backend (near real-time, $99/yr)
```
GitHub Actions cron (every 5–10 min) ──> GitHub API
        └── new issue? ──> Apple Push Notification service (APNs) ──> your iPhone
iPhone app: manages repo list, registers for push, shows issue feed
```
- Notifications arrive within ~5–15 min (GitHub's cron can run late under load).
- **Needs the paid Apple Developer Program ($99/year)**; push notifications are not
  available on free accounts.
- Repo list has to reach the backend: simplest is a `repos.txt` in the backend repo,
  which the app edits through the GitHub API using your token.
- More moving parts: APNs signing key (stored as a GitHub Actions secret, never in code),
  device token, two codebases.

### Recommended path
Build **A first**. Its parts (repo list, GitHub fetch, "what's new" logic, issue feed UI)
are all reused by B. If the delay bothers you after a week of use, add the backend.

## App design (shared by A and B)
- **Screens**: Repo list (add/remove `owner/repo`) → Issue feed per repo → tap opens issue in Safari.
- **Storage**: SwiftData (built in) for repos + highest issue number seen per repo.
- **Networking**: `URLSession` → `GET /repos/{owner}/{repo}/issues?state=all&sort=created&direction=desc&per_page=100`.
  Drop pull requests (they have a `pull_request` field). New = number > last seen.
- **First check of a new repo seeds the number**, no notifications for issues that already exist.
- **Token (optional)**: 60 req/hr without one, 5000 with. Stored in the iOS Keychain, never in code.
- **No third-party packages.**

Tech: SwiftUI, SwiftData, BackgroundTasks, UserNotifications. Xcode 27.1 / iOS 27.

## Testing
- Unit tests (Swift Testing) for: PR filtering, "new since last seen", first-run seeding,
  decoding a saved GitHub API response.
- Simulator: add a repo, check the feed loads; trigger the background task from Xcode's
  debugger to check notifications without waiting for iOS.
- Real test: on your iPhone, watch a repo you own, open a test issue, confirm one notification.

## Failure modes handled
- Repo typo / private repo → shown as an error on that repo row; others keep working.
- Rate limited (403/429) → skip this check, show "rate limited" in the UI.
- Offline → skip; state unchanged, nothing lost.

## Not building (add when needed)
Label/keyword filters, multiple accounts, iPad/Mac versions, widgets.

## Status (2026-11-07)
Decision: build Option A (app only) now; Telegram bot next.
Option A built: `Ping/` (app), `PingTests/` (Swift Testing), `project.yml` (xcodegen).

Run:
- `xcodegen` → open `Ping.xcodeproj` → run on a simulator or your iPhone.
- On a phone: change `com.dhruvsharma.Ping` (in `project.yml`, both bundle id and task id
  in `Checker.swift`) to your own id, then pick your Apple ID team in Signing.
- Test the background check on a real device: pause in Xcode, then in lldb:
  `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.dhruvsharma.Ping.refresh"]`
- App icon: originals in `Design/` (light + dark); cropped to 1024px in `Ping/Assets.xcassets/AppIcon.appiconset`. Logo uses GitHub's Octocat: fine for personal use, not for App Store release.
- Code is grouped by feature: `App/`, `Repos/`, `Issues/`, `Checking/`. After adding files, run `xcodegen`.
