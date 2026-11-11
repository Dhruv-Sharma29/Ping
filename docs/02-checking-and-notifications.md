# 02 — Checking and notifications

## The guarantee

Whenever a check completes for a repo, Ping has notified you **exactly once** about every issue that

- was opened after you added the repo (or after the first successful check, see below), and
- is among the newest 100 issues and pull requests at the time of the check,

and has **not** notified you about any pull request or any issue that already existed.

What Ping does **not** guarantee is *when* a check completes. That's decided by how you use the
app and by iOS.

## When checks run

| Trigger | Where | Runs when | Notes |
| --- | --- | --- | --- |
| App launch | `RepoListView` `.task` → `start()` | Every cold start | Also requests notification permission the first time |
| Return to the app | `RepoListView` `.onChange(of: scenePhase)` → `.active` | Every time Ping comes to the front | Also re-reads notification permission |
| Pull to refresh | `.refreshable` on the repo list | When you pull | Returns immediately if a check is already running |
| Adding a repo | `RepoListView.add` | Right after insert | Seeds the new repo's `lastSeen` |
| Background refresh | `.backgroundTask(.appRefresh(Checker.taskID))` in `PingApp` | When iOS decides | Not before 15 minutes after it was requested; often much later |

### Background refresh, precisely

- Ping asks for a wake-up (`BGAppRefreshTaskRequest`, `earliestBeginDate` = now + 15 min) every
  time it goes to the background, and again as the **first** thing the background handler does,
  because requests are one-shot.
- `earliestBeginDate` is a floor, not a schedule. iOS weighs how often you use the app, battery,
  Low Power Mode and the network, so the actual gap can be hours **[verify]** by measuring on
  the iPhone 15 (row's "Checked … ago").
- After you **swipe Ping away** in the app switcher, iOS doesn't run its background tasks until you
  open it again. The same applies if Background App Refresh is off for Ping or system-wide.
- If iOS ends the background time mid-check, the Swift task is cancelled. `Checker.run` stops,
  keeps the repos already checked, and saves. The rest are checked next time.
- `BGTaskScheduler` doesn't run in the Simulator; `submit` fails there and the error is ignored on
  purpose (`Checker.scheduleRefresh`).

## How "new" is decided

```text
fetch newest 100 (issues + PRs), state=all, sorted by creation, newest first
drop items that have a pull_request field
if lastSeen is nil          → new = none            (first check: seed only)
else                        → new = issues with number > lastSeen
notify each new issue
lastSeen = max(lastSeen ?? 0, highest issue number in this fetch)
```

`GitHub.newIssues` and `GitHub.decode` are pure functions with unit tests ([03](03-verification.md)).

### Edge cases

| Case | What happens |
| --- | --- |
| Repo has no issues yet | First check sets `lastSeen = 0`; the first issue ever opened will notify |
| Only PRs in the newest 100 | `lastSeen` stays as it was; later issues still compare against it correctly |
| First check fails (offline, typo, rate limit) | `lastSeen` stays `nil`; the first *successful* check seeds. Issues opened between adding and that check are **not** notified |
| More than 100 issues + PRs opened between two checks | Issues beyond the newest 100 are never notified. Marked `ponytail:` in `GitHub.swift`; fix is pagination ([05](05-risks.md) § R2) |
| Issue opened and closed between checks | Still notified (`state=all`) |
| Issue deleted or transferred away | It simply isn't in the list; no effect |
| Repo renamed or transferred | GitHub redirects the API request **[verify]** with a renamed repo; the stored name stays the old one |
| Repo deleted or made private | 404 → row shows "Repo not found, or it's private"; other repos unaffected |
| Same repo added twice, different case | Second add is ignored (case-insensitive check in `RepoListView.add`) |
| Two checks start together | The second returns immediately (`Checker.running`) |

## Notifications

- **Content:** title `New issue in owner/repo`, subtitle `by login · Role` (for example
  *by FranzBusch · Member*), body `#number title`, default sound, and the issue's web URL in
  `userInfo`. Only public data.
- **Identifier:** `owner/repo#number`, so a repeat for the same issue replaces rather than stacks.
- **While the app is open:** `NotificationDelegate.willPresent` returns banner + list + sound, so
  checks made on launch or refresh are visible.
- **Tap:** `NotificationDelegate.didReceive` opens the URL with `UIApplication.open`, which goes to
  Safari (or the GitHub app if it claims the link **[verify]**).
- **Permission:** requested once on first launch. If denied, Ping still checks and updates rows, but
  posts nothing, and shows the *Notifications Are Off* card with an **Open Settings** button.

## Errors

`GitHub.issues(for:)` maps HTTP status codes to messages shown on the repo row (`RepoRow`):

| Status | Message | Meaning |
| --- | --- | --- |
| 200 | — | Success |
| 404 | Repo not found, or it's private | Typo, private, or deleted |
| 403, 429 | GitHub rate limit hit. Ping will retry later | Unauthenticated limit reached for this IP address (403 can also mean other refusals) |
| other | GitHub error *code* | Shown as-is |
| network failure | The system's message (e.g. "The Internet connection appears to be offline.") | No state changes |

Errors never change `lastSeen`, so nothing is lost: the next successful check catches up (within
the 100-item window).
