# 04 — Roadmap

## M1 — Plan and choose an architecture · **Done**

| Acceptance | Evidence |
| --- | --- |
| Problem and constraint stated (iOS can't poll on a timer) | [`PLAN.md`](../PLAN.md) § The hard constraint |
| Options compared with cost and timeliness | Option A (app only, free) vs B (app + backend + push, paid program) |
| Choice recorded | Option A first, then a Telegram bot ([`PLAN.md`](../PLAN.md) § Status) |

## M2 — App-only MVP · **Done in the Simulator; background path unverified**

| Acceptance | Evidence |
| --- | --- |
| Add and remove repos, input validated | `AddRepoSection`, `GitHub.normalize`; tests + [03](03-verification.md) § M1 |
| Seed on first check; notify only newer issues; drop PRs | `GitHub.newIssues`, `GitHub.decode`; tests + § M2 |
| Tap opens the issue | `NotificationDelegate`; § M4 |
| Background refresh wired | `PingApp` `.backgroundTask`, `Checker.scheduleRefresh`; **not observed** ([03](03-verification.md) § On the device) |

## M3 — Design pass and branding · **Done**

| Acceptance | Evidence |
| --- | --- |
| Screens follow SwiftUI design and accessibility guidance (Dynamic Type styles, 44 pt targets, labels, `ContentUnavailableView`) | `Repos/`, `Issues/`; skill-guided review during the redesign |
| Light and dark app icons, accent colour from the logo | `Assets.xcassets`; `Design/make-icons.py` reproduces the icons |
| One type per file, feature folders | Repository layout in [README](../README.md) |

## M4 — Running on the iPhone · **In progress**

| Acceptance | Status |
| --- | --- |
| Signed and installed with a free team | Done (2026-11-07) |
| Opens and checks on the device | Waiting for the user to trust the developer profile |
| Background check observed (S7) | Not started: RUNBOOK § 6 |

## M5 — Telegram bot · **Next**

Chosen as the next step: a server sends messages, so delivery no longer depends on iOS waking the
app, and Telegram's Bot API is free with no message templates.

Sketch (to be planned properly before building):
- A scheduled job (e.g. GitHub Actions cron, every 5–10 minutes) runs the same rule as
  `GitHub.newIssues`, keeping `lastSeen` per repo in a small state file.
- New issues are sent with the Bot API `sendMessage` to the user's chat.
- The bot token lives in the job's secret store, never in the repo or the app.
- Open questions: where the repo list lives (a file in the repo vs chat commands, which need an
  always-on webhook), and whether the iPhone app and the bot share one list.

## M6 — Option B: backend + Apple push · **Not planned**

Only if the Telegram bot isn't enough. Needs the paid Apple Developer Program, an APNs key, and a
way for the app to register its device token. Everything in M2's checking logic carries over.

## Open items (smaller)

| Item | Why | Where |
| --- | --- | --- |
| Optional GitHub token in the Keychain | 5,000 requests/hour instead of 60; private repos | Planned in `PLAN.md`, not built ([06](06-implementation-notes.md) § 1) |
| Pagination past 100 items | Busy repos with long gaps between checks | `GitHub.issues` (`ponytail:` comment) |
| Show when Background App Refresh is off | Users otherwise wonder why nothing arrives | `UIApplication.backgroundRefreshStatus` |
| Tests for the network layer | Status mapping is untested | `URLProtocol` stub |
| Replace the Octocat in the logo | Needed before any public release | [05](05-risks.md) § R7 |
| Choose a license | None yet; all rights reserved by default | Repository root |
| `.gitignore` for `build/` (~170 MB) | Before this folder becomes a git repository | Repository root |
