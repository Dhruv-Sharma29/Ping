# 06 — Implementation notes: where the code departs from the plan

[`PLAN.md`](../PLAN.md) was written before any code. This file records where the build differs,
and the bugs found along the way, so the plan doesn't have to be rewritten to stay honest.

## Departures from the plan

### 1. GitHub token: built later than planned (2026-11-07)

Now built as planned (Account → GitHub Token, Keychain). The original note follows.

#### Original note

`PLAN.md` § App design lists an optional token stored in the Keychain. It isn't built: every
request is unauthenticated. Consequences: 60 requests/hour per IP, public repos only
([05](05-risks.md) § R3). Building it means a settings screen, Keychain storage and an
`Authorization` header in `GitHub.issues`.

### 2. "Trigger the background task from the debugger" in the Simulator

`PLAN.md` § Testing suggested testing the background task in the Simulator. `BGTaskScheduler`
doesn't run there (`submit` fails), so that test moved to a real device (RUNBOOK § 6).

### 3. Bundle ID changed from `com.example.Ping` to `com.dhruvsharma.Ping`

The placeholder couldn't be signed. The change touched `project.yml` (bundle ID and permitted
task ID) and `Checker.taskID`. The Simulator then held two apps; the old one was uninstalled.

### 4. Folder layout

The first version was five files in one folder. The redesign split it into feature folders with
one type per file (`App/`, `Repos/`, `Issues/`, `Checking/`) to follow the SwiftUI review guidance.

### 5. App icon source

First a code-drawn green "ping rings" icon (`Tools/make-icon.swift`, since deleted). Then replaced
by the user's P + Octocat logo, in light and dark variants, built by `Design/make-icons.py`.

## Served behaviour vs plan wording

### 6. Rate-limit message

The plan says *show "rate limited" in the UI*. The build shows *GitHub rate limit hit. Ping will retry
later.* on the repo row for HTTP 403 and 429. A 403 can also mean other refusals; the message
assumes rate limiting.

## Bugs found while building

### 7. Swift 6 rejected `UIApplication.open` from the notification delegate

The delegate's tap callback is `nonisolated`. Calling the async `open(_:)` sent a non-Sendable
options dictionary across actors, which is a compile error in Swift 6 mode. Fix: hop to the main
actor and use the completion-free overload (`MainActor.run { UIApplication.shared.open(url) }`).

### 8. Issue numbers shown as "#94,089"

`Text("#\(issue.number)")` formats the `Int` with the locale's grouping separator. Fix:
`String(issue.number)` inside the interpolation. Found in the Simulator.

### 9. Only 3 issues listed for `swiftlang/swift`

The first version requested 30 items. That repo opens many more PRs than issues, so after dropping
PRs only 3 issues remained. This also meant a gap of 30 items between checks would miss issues.
Fix: 100 per request (the API's maximum page size **[verify]**). `PLAN.md` was updated to match.

### 10. Whole issue row tinted with the accent colour

`Link` applies the accent tint to its label, overriding `.foregroundStyle(.primary)`. Titles and
metadata turned green, later purple. Fix: `.tint(.primary)` on the `Link`.

### 11. Duplicate notifications from overlapping checks (prevented, not observed)

On launch, `.task` and the scene-phase change can both start a check. Both would read the same
`lastSeen` and notify twice. Prevented up front by the `running` flag in `Checker`; the
notification identifier `owner/repo#number` is a second line of defence.

### 12. Top spark of the logo clipped by the icon mask

The user's logo filled the icon edge to edge; iOS's rounded mask cut off the top-right spark
(seen on the Simulator home screen). Two fixes were tried and dropped: a blurred-background
fill (visible square, purple smear) and a feathered edge (faded sparks, faint outline). The kept
fix separates the logo from its backdrop by colour difference, scales it to 84%, and places it on a
gradient made from the backdrop's corner colours (`Design/make-icons.py`). Re-running the script
produces byte-identical icons to those in the app.

## Documentation drift found while writing these docs

| Where | Said | Reality |
| --- | --- | --- |
| `PLAN.md` § App design, Networking | `per_page=30` | 100 (§ 9); corrected in `PLAN.md` |
| `PLAN.md` § App design, Token | Optional token in the Keychain | Not built (§ 1); left in the plan as intended work |
| `PLAN.md` § Testing | Trigger the background task in the Simulator | Not possible (§ 2) |

### 13. Background checks reported "not working" (2026-11-08)

No broken line was found: the `fetch` mode, task ID and handler were all correct on the device build.
What was weak, and what changed:

- **Wake-ups were requested only when leaving the app.** Now also on every launch
  (`onChange(of: scenePhase, initial: true)`).
- **Repos were fetched one at a time** (~10 s for 10 repos) inside a ~30 s background window.
  Now in parallel (`Checker.fetchAll`); an interrupted check keeps what finished.
- **Only one kind of wake-up.** Added a `BGProcessingTask` (`com.dhruvsharma.Ping.process`,
  network required, power not required), which iOS tends to run during idle/charging time.
- **No way to see what iOS did.** `BackgroundLog` records the last request, request errors and
  every background run with its result; shown in Account → Background Checks. Repos shows a card
  when Background App Refresh is off.
- **Crash caught by the tests:** submitting a request in `App.init` happens before SwiftUI
  registers its `.appRefresh` handler, and iOS stops the app ("submission without registration").
  Requests are now submitted from the scene phase handler instead.

Verified: on the iPhone 15, iOS accepted both requests (no error logged; earliest 09:46).
**Not verified:** a background run on the device. `lldb` attach from the terminal hung; use Xcode's
debugger (RUNBOOK § 6) or read Account → Background Checks after some hours.
