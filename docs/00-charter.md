# 00 — Charter

## The problem

People who contribute to or maintain open-source projects want to know quickly when a new issue
is opened on a handful of specific repositories, for example to pick up good first issues before
someone else does, or to triage reports on their own project.

GitHub's own notifications can do this (Watch → Custom → Issues), but they arrive mixed with
every other notification for watched repos, and the setting is per repo on the website. Ping is a
single place on the phone that answers one question per repo: *has anyone opened an issue since I
last looked?*

## Who it's for

The first user is the author: a student contributor who wants to catch new issues on chosen repos
from an iPhone. Success is measured for that user ([Success criteria](#success-criteria)), not for
a general audience.

## What it does

**Input:** a list of public repositories (`owner/repo` or a github.com link), entered in the app.

**Output:**
1. A local notification per new issue: `New issue in owner/repo` / `by login · Role` /
   `#123 Title`. Tapping it opens the issue (`Checker.notify`, `NotificationDelegate`).
2. A per-repo list of the newest issues with open/closed state, age, who opened each one and
   their role in the repo (`IssueListView`, `AuthorLine`).
3. Per-repo status: when it was last checked, or why the check failed (`RepoRow`).
4. An **Issues** tab with every recent issue across all watched repos, notified or not, searchable
   by title, author, repo or number and filterable by state, repo and opener (`AllIssuesView`).

## Scope

### In
- Public repositories, read through GitHub's unauthenticated REST API.
- Issues only. Pull requests share GitHub's issue list and are filtered out.
- Checks when the app opens, on pull-to-refresh, and on iOS background refresh.
- Local notifications, with banners shown even while the app is open.
- Runs on a personal iPhone with a free Apple ID.

### Out (deliberately)
- **Private repositories.** They need a token on the phone, and the plan's Keychain design isn't
  built ([06](06-implementation-notes.md) § 1).
- **Real-time delivery.** Impossible without a server; see Option B in [`PLAN.md`](../PLAN.md) and
  the Telegram bot in [04](04-roadmap.md).
- **Filters** (labels, keywords, authors). Useful later, not needed to answer the core question.
- **Comments, PRs, releases.** Different events with different noise levels; Ping stays about issues.
- **iPad, Mac, widgets.** Not needed by the first user.

## Non-goals

- **Guaranteed timing.** iOS decides when background work runs. Ping is correct whenever it runs;
  it does not promise *when* ([02](02-checking-and-notifications.md)).
- **App Store release.** The logo contains GitHub's trademark and signing uses a free team
  ([05](05-risks.md) § R5, R7).
- **Replacing GitHub notifications.** Ping covers one narrow use case.

## Success criteria

| # | Criterion | How it's checked | Status |
|---|---|---|---|
| S1 | Adding a repo never notifies about issues that already existed | Unit test `firstCheckOnlySeeds`; Simulator run ([03](03-verification.md) § M2) | Met |
| S2 | Each issue newer than the last seen produces exactly one notification | Unit test `onlyIssuesAfterLastSeen`; Simulator: 2 new → 2 banners | Met |
| S3 | Pull requests never produce notifications | Unit test `decodeDropsPullRequests` | Met |
| S4 | Tapping a notification opens that issue | Simulator ([03](03-verification.md) § M4) | Met |
| S5 | Bad input is rejected before it reaches a URL | Unit test `normalizeRejects` (6 cases); Simulator inline error | Met |
| S6 | A failing repo shows why and doesn't stop the other repos | Code path in `Checker.run` (per-repo `do/catch`) | Built, not observed: no 404 or rate-limit row has been seen yet |
| S7 | The app notices new issues while in the background on a real iPhone | Device run ([RUNBOOK](../RUNBOOK.md) § 6) | **Not yet checked** |
| S8 | The user can tell when notifications are off and fix it | `NotificationsOffSection` with Open Settings | Built, not observed (permission was always allowed in tests) |

## The honest risk to the goal

The request was "notify me as a new issue is raised". Option A can't promise that: on a real
phone the background check may run every half hour, every few hours, or not at all, and nothing in
the app can force it. Ping's correctness (no missed issues within 100 per check, no duplicates, no
old issues) holds whenever it runs; its *timeliness* is up to iOS. If timeliness matters, the
answer is a server: the Telegram bot or Option B ([04](04-roadmap.md), [05](05-risks.md) § R1).
