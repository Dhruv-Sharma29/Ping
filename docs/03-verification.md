# 03 — Verification

Three kinds of evidence, in decreasing strength: automated unit tests, manual runs in the
Simulator, and manual runs on the device. Each section says what was observed, how, and what it
does **not** show.

## Unit tests

`PingTests/PingTests.swift`, Swift Testing. Last run **2026-11-07**, iPhone 18 Pro simulator
(iOS 27.0), Xcode 27.1: **30 tests, 45 cases, all passed** (`** TEST SUCCEEDED **`).

| Test | Cases | Checks |
| --- | --- | --- |
| `decodeDropsPullRequests` | 1 | A sample response with 2 issues and 1 PR decodes to issues 12 and 10 |
| `decodeReadsDatesAndState` | 1 | `created_at` decodes as ISO 8601; `state: "open"` → `isOpen` |
| `decodeReadsAuthorAndRole` | 1 | `user.login` and `author_association` decode (`alice`/Member, `carol`/First-time contributor); avatar URL gets `s=64` |
| `unknownRoleFallsBackInsteadOfFailing` | 1 | An unrecognised role decodes as `.none` instead of throwing |
| `roleLabels` | 8 | Every GitHub role has the right label; only Owner, Member, Collaborator count as maintainers |
| `noFilterShowsEverything` | 1 | Default filter keeps all items and isn't "active" |
| `searchMatchesTitleAuthorRepoAndNumber` | 1 | Case-insensitive title, author and repo matches; `#102` and `7` match the exact number only |
| `filtersCombine` | 1 | State, repo and opener filters combine with each other and with search |
| `firstCheckOnlySeeds` | 1 | `lastSeen == nil` → no new issues |
| `onlyIssuesAfterLastSeen` | 1 | `lastSeen = 10` → [12]; `lastSeen = 12` → [] |
| `normalizeAccepts` | 4 | `apple/swift`, padded `https://github.com/...`, `github.com/...git/`, `www.github.com/vercel/next.js` |
| `normalizeRejects` | 6 | `apple`, `a/b/c`, `apple/..`, `../x`, `apple/sw ift`, empty |

**Not covered by tests:** the HTTP request and status mapping, SwiftData persistence, posting and
presenting notifications, the `running` guard, background scheduling, and all views. The sample
JSON is hand-trimmed, not a recorded GitHub response.

## Manual runs in the Simulator

iPhone 18 Pro, iOS 27.0, 2026-11-07, against the live GitHub API with `swiftlang/swift`.

### M1 — Adding a repo
- Pasted `https://github.com/swiftlang/swift`; the row showed `swiftlang/swift` (later as *swift* /
  *swiftlang* with avatar).
- Submitted `swiftlang/swift` again: no second row.
- Typed `not a repo`: inline error *Use owner/repo, for example apple/swift*, nothing added.

### M2 — Seeding and new-issue notifications
- After the first check, the store held `lastSeen = 94089` (read with `sqlite3`, RUNBOOK § 4), and
  no notification was shown. **Shows:** S1.
- Set `lastSeen = 94064` in the store and relaunched. Exactly two banners appeared,
  *#94089 With compilation caching…* and *#94065 Missed comparator specialization…*, and
  `lastSeen` returned to 94089. The newest issues at the time were #94089, #94065, #94062, so
  these were exactly the issues above 94064. **Shows:** S2, and banners while the app is open.
- **Does not show:** a notification for an issue that was really opened after seeding. The test
  simulates "missed" issues by lowering the stored number.

### M3 — Update with an existing store
- The redesign added `lastChecked` to `Repo`. The previous build's store opened without errors and
  the row showed *Checked now*. **Shows:** SwiftData's automatic migration for an added optional field.

### M4 — Tapping a notification
- Tapping the banner opened Safari on github.com. Tapping an issue row (#94065) opened that issue
  page in Safari. **Shows:** S4. **Does not show:** behaviour with
  the GitHub app installed.

### M5 — UI states
- Issue list: titles in primary colour with green open-issue icons, `#94089 · opened 3 hours ago`
  (no thousands separator); a full screen of issues instead of 3 after moving to 100 items per
  request (the total count wasn't recorded).
- App icon on the home screen (light appearance): not clipped by the corner mask after the fix in
  [06](06-implementation-notes.md) § 12.
- **Not observed:** dark-appearance icon on a home screen, the *Notifications Are Off* card, a
  rate-limit or 404 error row, Dynamic Type at large sizes, VoiceOver.

### M6 — Who opened the issue, and their role
- Issue list for `swiftlang/swift` showed avatar, username and a role badge on every row. Compared
  with the raw API response fetched the same minute: #94089 Dharin-shah, #94065 wlstnals4028,
  #94062 Joseph-Cursio, #94059 unixcorn4114 all *No association* (`NONE`); #94045 FranzBusch
  *Member* (highlighted); #94019 ptoffy *Contributor*. All matched. The newest 100 items held 16
  issues: 8 `NONE`, 6 `CONTRIBUTOR`, 2 `MEMBER`.
- With `lastSeen` lowered to 94044, the banner read *by Dharin-shah · No association* and iOS
  grouped the rest as *You have 7 new Ping notifications*: the 7 issues above #94044.
- **Not observed:** Owner, Collaborator, First-timer or Mannequin badges on real data (labels are
  unit tested); the highlighted badge in dark mode.

### M7 — Issues tab, search and filters
- With `swiftlang/swift` and `swiftlang/swift-format` watched, the tab showed **34 issues** from
  both repos, newest first, each labelled with its repo.
- Search "fran" → 2 issues, both by FranzBusch (case-insensitive author match).
- Filter → Opened By → Maintainers → 4 issues across both repos, all *Member*; the filter icon
  switched to its filled variant.
- **Not observed:** the State and Repository filters on screen (unit tested), the "Couldn't load"
  footer, the no-results and no-repos screens.

## On the device

iPhone 15 (`iPhone15,4`), 2026-11-07.

- **Build and signing:** succeeded with the free Personal Team; Xcode created
  *iOS Team Provisioning Profile: com.dhruvsharma.Ping*.
- **Install:** succeeded (`devicectl device install app`).
- **Launch:** refused by iOS: *profile has not been explicitly trusted by the user*. Expected for a
  first install with a free team; the user must trust the profile on the phone (RUNBOOK § 5).
- **Nothing at runtime has been observed on the device yet,** including S7 (background checks).

## What would close the gaps

| Gap | How to close it |
| --- | --- |
| S7, background check on a device | RUNBOOK § 6: lldb simulated launch, then a real-world wait recording "Checked … ago" times |
| A genuinely new issue end to end | Add a repo you own, open an issue, bring Ping to the front |
| Error rows (404, rate limit) | Add a nonexistent repo; for rate limit, refresh repeatedly on a shared network |
| Notifications-off card | Deny permission (Settings → Notifications → Ping) and open the app |
| Network code untested | Inject a `URLSession` or `URLProtocol` stub and test status mapping |
| Accessibility | Run with the largest Dynamic Type size and VoiceOver |
