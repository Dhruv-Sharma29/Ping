# Ping: Documentation

An iPhone app that notifies you when someone opens a new issue on GitHub repositories you choose,
with no server and no credentials.

These docs are the design record. Read them in order the first time and use them as reference
afterwards. [`README.md`](../README.md) is the overview; [`RUNBOOK.md`](../RUNBOOK.md) has every
command.

## Reading order

| # | Doc | What it settles |
|---|---|---|
| 00 | [Charter](00-charter.md) | Problem, who it's for, scope, non-goals, success criteria and how each is checked |
| 01 | [Architecture](01-architecture.md) | Components, data model, the check path, the decisions table |
| 02 | [Checking and notifications](02-checking-and-notifications.md) | How "new" is decided, when checks run, what's guaranteed and what isn't |
| 03 | [Verification](03-verification.md) | Unit tests, manual checks in the Simulator and on the device, and what is still unverified |
| 04 | [Roadmap](04-roadmap.md) | Milestones with honest status; the Telegram bot and backend options |
| 05 | [Risks](05-risks.md) | Product risks, delivery risks, and which claims are safe to make |
| 06 | [Implementation notes](06-implementation-notes.md) | Where the code departs from [`PLAN.md`](../PLAN.md), and bugs found while building |

## The one-paragraph version

GitHub can already email you about new issues, but only for repos you "watch", mixed in with
everything else. Ping is a focused alternative: you list the repos, it tells you about new issues
and nothing else. The interesting constraint is iOS itself. An app can't run on a timer in the
background; iOS grants background time when it chooses, and not at all after a force-quit. So Ping
is built to be correct whenever it does run, rather than pretending to be real-time: it remembers
the highest issue number seen per repo, treats anything above it as new, never notifies about
issues that existed before you added the repo, and also checks every time you open the app. Real-time
delivery needs a server, which is what the Telegram bot and Option B on the roadmap are for.

## Status

**As of 2026-11-07:** Option A (app only) is built. Its logic is unit tested (30 tests, 45 cases)
and the full flow (add repo → seed → new issue → notification → tap opens issue) was verified in
the iOS Simulator. It is installed on an iPhone 15 but has not run there yet, and the background
check has not been observed on any device. See [03](03-verification.md) for the evidence and
[04](04-roadmap.md) for what's next.

## Conventions used in these docs

- **MUST / SHOULD / MAY** are load-bearing. MUST items are acceptance criteria.
- **[verify]** marks a claim not confirmed against a primary source or a run in this project.
  Each one says what would confirm it.
- Every behaviour claim names the file, test or manual check it comes from.
- "Verified" means observed in a run recorded in [03](03-verification.md), on the device and
  date stated there. It never means "will always work on every iPhone".
