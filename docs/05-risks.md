# 05 — Risks and failure modes

Two kinds of risk. **Product risks** mean Ping works as built but doesn't do what the user hoped.
**Delivery risks** mean it stops running or can't be shipped. The first kind matters more here,
because an app that shows "Checked now" every time you open it looks finished.

## Product risks

### R1 — Background checks are rare or never happen *(high likelihood, undermines the main goal)*

iOS decides when `BGAppRefreshTask` runs, based on usage, battery and network. For an app opened
rarely, that can mean hours between checks or none at all, and none after a force-quit.

**Detection:** each repo row shows *Checked … ago*. If it only ever updates when you open the app,
background refresh isn't running.

**Mitigation:** checks on every launch and return to the app; the guarantee in
[02](02-checking-and-notifications.md) holds whenever a check runs. The real fix is a server: the
Telegram bot (M5) or Option B (M6) in [04](04-roadmap.md).

### R2 — Missed issues in busy repos *(low for most repos, real for very active ones)*

Each check reads the newest 100 issues and PRs. If more than 100 are opened between two checks,
the older ones are never notified. Combined with R1, long gaps make this more likely.

**Detection:** none in the app today.
**Mitigation:** follow GitHub's `Link: rel="next"` pages until reaching `lastSeen`.

### R3 — Rate limit on shared networks *(medium)*

Unauthenticated requests are limited to 60 per hour **per IP address** **[verify]** against
GitHub's REST API rate-limit docs. On campus Wi-Fi, where many devices share one public address, other
people's requests count too. Each check uses one request per repo, opening a repo's issue list uses one more, and opening or
refreshing the Issues tab uses one per repo again.

**Detection:** red row *GitHub limit reached. Resets at 8:42* (time taken from GitHub's
`x-ratelimit-reset` header). Observed 2026-11-07 on a phone on 5G: the hour's 60 were gone in
about a minute of use.

**Mitigation (built 2026-11-07):**
- **Optional GitHub token** in Account → GitHub Token: checked against GitHub's `/rate_limit`
  before saving, stored only in the Keychain (`AfterFirstUnlockThisDeviceOnly`), sent only as an
  `Authorization` header. Raises the limit to 5,000/hour **[verify]** for that user alone.
- **Wait for the reset:** after a rate-limit response Ping sends nothing to that API (core or
  search, tracked separately) until the reset time (`RateLimit`).
- **Star counts cached for a day** on the phone (`StarCache`), forgotten after a week unseen.
- **Automatic checks at most every 5 minutes** (`Checker.shouldRun`); pull to refresh and adding a
  repo still check at once. Measured in the Simulator: a check of 2 repos used 2 requests; reopening
  the app 13 seconds later used 0.

**Newer features use the same budget.** Star counts cost one request per repo the first time it
appears (cached for a day); Explore rows come from many different repos, so a long Explore
scroll can use most of the hour's 60. Explore and For You also use GitHub's search API, limited
to 10 unauthenticated requests a minute **[verify]**. An optional GitHub token (5,000/hour) is
the fix; see [04](04-roadmap.md).

### R4 — Notifications denied *(low, handled)*

Ping can't notify, but would otherwise look normal. **Mitigation:** the *Notifications Are Off*
card with **Open Settings** (built, not yet observed; [03](03-verification.md) § M5).

### R5 — Silent failure of the first check *(low)*

If the first check after adding a repo fails, `lastSeen` stays empty and the next successful check
seeds, so issues opened in between are not notified ([02](02-checking-and-notifications.md) § Edge cases).

## Delivery risks

### R6 — Free signing expires every 7 days *(certain with a free team)*

The app stops opening until it's reinstalled from the Mac (RUNBOOK § 5). Data is kept.
**Mitigation:** reinstall weekly, or join the paid program.

### R7 — Trademark in the logo *(certain, only matters for distribution)*

The supplied logo contains GitHub's Octocat. GitHub's logo guidelines don't allow using it as
another app's icon **[verify]** against GitHub's current logo policy. Fine for a personal build;
**MUST** be replaced before TestFlight or the App Store.

### R8 — Private debugging selectors *(low)*

The lldb commands in RUNBOOK § 6 use private `BGTaskScheduler` selectors. They are safe only in the
debugger; they **MUST NOT** appear in code, or App Review rejects the app.

### R9 — Tooling drift *(medium over time)*

The project relies on XcodeGen and Swift 6 settings. A new Xcode can change defaults or diagnostics.
**Mitigation:** the toolchain is recorded in the RUNBOOK; regenerate and run the tests after upgrades.

## Claim hygiene

| Say | Don't say |
| --- | --- |
| Ping checks when you open it, pull to refresh, and when iOS allows a background refresh | Ping notifies you instantly / every 15 minutes |
| The notification flow was verified in the iOS Simulator | Notifications work on iPhone |
| Unit tests cover parsing, PR filtering, seeding and input validation (30 tests, 45 cases) | Ping is fully tested |
| No server, no token: only requests to GitHub leave the phone | Ping is completely private (GitHub sees your IP and which repos you check) |
| New issues within the newest 100 items per check are notified once | Ping never misses an issue |

## The question to have a real answer for

*"If the background check doesn't run, what's the point of the app?"*

Honest answer: on its own, Option A is a fast "what's new since I last looked" screen plus
best-effort alerts. It's correct whenever it runs, free, and private, and it was the right first
step because its checking logic carries over unchanged. Reliable, timely alerts need something that
runs on a schedule outside the phone, which is why the Telegram bot is next.
