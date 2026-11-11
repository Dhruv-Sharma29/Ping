import Foundation
import Testing
@testable import Ping

// Trimmed shape of a real GitHub /issues response: newest first, one PR mixed in.
private let sample = Data("""
[
  {"number": 12, "title": "Crash on launch", "state": "open", "created_at": "2026-11-07T10:00:00Z",
   "html_url": "https://github.com/a/b/issues/12", "author_association": "MEMBER",
   "user": {"login": "alice", "avatar_url": "https://avatars.githubusercontent.com/u/1?v=4"}},
  {"number": 11, "title": "Fix typo", "state": "open", "created_at": "2026-11-07T10:00:00Z",
   "html_url": "https://github.com/a/b/pull/11", "author_association": "CONTRIBUTOR",
   "user": {"login": "bob", "avatar_url": "https://avatars.githubusercontent.com/u/2?v=4"}, "pull_request": {"url": "x"}},
  {"number": 10, "title": "Old bug", "state": "closed", "created_at": "2026-11-01T10:00:00Z",
   "html_url": "https://github.com/a/b/issues/10", "author_association": "FIRST_TIME_CONTRIBUTOR",
   "user": {"login": "carol", "avatar_url": "https://avatars.githubusercontent.com/u/3?v=4"}}
]
""".utf8)

@Test func decodeDropsPullRequests() throws {
    #expect(try GitHub.decode(sample).map(\.number) == [12, 10])
}

@Test func decodeReadsDatesAndState() throws {
    let issue = try #require(try GitHub.decode(sample).first)
    #expect(issue.isOpen)
    #expect(issue.createdAt == Date(timeIntervalSince1970: 1_794_045_600))
}

@Test func decodeReadsAuthorAndRole() throws {
    let issues = try GitHub.decode(sample)
    #expect(issues.map { $0.author?.login } == ["alice", "carol"])
    #expect(issues.map(\.role) == [.member, .firstTimeContributor])
    #expect(issues[0].author?.smallAvatarURL.absoluteString == "https://avatars.githubusercontent.com/u/1?v=4&s=64")
}

@Test func unknownRoleFallsBackInsteadOfFailing() throws {
    let roles = try JSONDecoder().decode([AuthorRole].self, from: Data(#"["SOMETHING_NEW", "OWNER"]"#.utf8))
    #expect(roles == [.none, .owner])
}

@Test(arguments: [
    ("OWNER", "Owner", true), ("MEMBER", "Member", true), ("COLLABORATOR", "Collaborator", true),
    ("CONTRIBUTOR", "Contributor", false), ("FIRST_TIME_CONTRIBUTOR", "First-time contributor", false),
    ("FIRST_TIMER", "New to GitHub", false), ("MANNEQUIN", "Imported user", false), ("NONE", "No association", false),
])
func roleLabels(raw: String, label: String, isMaintainer: Bool) throws {
    let role = try #require(AuthorRole(rawValue: raw))
    #expect(role.label == label)
    #expect(role.isMaintainer == isMaintainer)
}

@Test func firstCheckOnlySeeds() throws {
    #expect(GitHub.newIssues(try GitHub.decode(sample), lastSeen: nil).isEmpty)
}

@Test func onlyIssuesAfterLastSeen() throws {
    let issues = try GitHub.decode(sample)
    #expect(GitHub.newIssues(issues, lastSeen: 10).map(\.number) == [12])
    #expect(GitHub.newIssues(issues, lastSeen: 12).isEmpty)
}

@Test(arguments: [
    ("apple/swift", "apple/swift"),
    ("  https://github.com/apple/swift ", "apple/swift"),
    ("github.com/apple/swift.git/", "apple/swift"),
    ("www.github.com/vercel/next.js", "vercel/next.js"),
])
func normalizeAccepts(input: String, expected: String) {
    #expect(GitHub.normalize(input) == expected)
}

@Test(arguments: ["apple", "a/b/c", "apple/..", "../x", "apple/sw ift", ""])
func normalizeRejects(input: String) {
    #expect(GitHub.normalize(input) == nil)
}

// MARK: - All-issues search and filters

private func item(_ repo: String, _ json: String) throws -> RepoIssue {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return RepoIssue(repo: repo, issue: try decoder.decode(Issue.self, from: Data(json.utf8)))
}

private func issueJSON(_ number: Int, _ title: String, state: String, role: String, login: String) -> String {
    #"{"number": \#(number), "title": "\#(title)", "state": "\#(state)", "created_at": "2026-11-07T10:00:00Z", "html_url": "https://github.com/x/y/issues/\#(number)", "author_association": "\#(role)", "user": {"login": "\#(login)", "avatar_url": "https://avatars.githubusercontent.com/u/1"}}"#
}

private func pool() throws -> [RepoIssue] {
    [
        try item("apple/swift", issueJSON(101, "Crash in parser", state: "open", role: "MEMBER", login: "alice")),
        try item("apple/swift", issueJSON(102, "Docs typo", state: "closed", role: "FIRST_TIME_CONTRIBUTOR", login: "bob")),
        try item("vercel/next.js", issueJSON(7, "Build crash on Linux", state: "open", role: "NONE", login: "carol")),
        try item("vercel/next.js", issueJSON(8, "Add dark mode", state: "open", role: "CONTRIBUTOR", login: "dave")),
    ]
}

private func ids(_ filter: IssueFilter, _ search: String = "") throws -> [String] {
    try pool().filter { filter.matches($0, search: search) }.map(\.id)
}

@Test func noFilterShowsEverything() throws {
    #expect(try ids(IssueFilter()).count == 4)
    #expect(IssueFilter().isActive == false)
}

@Test func searchMatchesTitleAuthorRepoAndNumber() throws {
    #expect(try ids(IssueFilter(), "crash") == ["apple/swift#101", "vercel/next.js#7"]) // title, case-insensitive
    #expect(try ids(IssueFilter(), "dave") == ["vercel/next.js#8"])                        // author
    #expect(try ids(IssueFilter(), "next.js").count == 2)                                   // repo
    #expect(try ids(IssueFilter(), "#102") == ["apple/swift#102"])                          // number with #
    #expect(try ids(IssueFilter(), "7") == ["vercel/next.js#7"])                            // number exactly, not 107
    #expect(try ids(IssueFilter(), "nothing like this").isEmpty)
}

@Test func filtersCombine() throws {
    #expect(try ids(IssueFilter(state: .closed)) == ["apple/swift#102"])
    #expect(try ids(IssueFilter(repo: "vercel/next.js", opener: .contributors)) == ["vercel/next.js#8"])
    #expect(try ids(IssueFilter(state: .open, opener: .maintainers)) == ["apple/swift#101"])
    #expect(try ids(IssueFilter(opener: .newcomers)) == ["apple/swift#102"])
    #expect(try ids(IssueFilter(opener: .noAssociation), "crash") == ["vercel/next.js#7"])
    #expect(IssueFilter(state: .open).isActive)
}

// MARK: - Paging every issue

@Test func pageKnowsWhenMoreMayExist() throws {
    let page = try GitHub.decodePage(sample, pageSize: 3)
    #expect(page.issues.map(\.number) == [12, 10])
    #expect(page.hasMore)                                                    // full page of 3 (PR included)
    #expect(page.oldest == Date(timeIntervalSince1970: 1_793_527_200))       // last raw item, #10
    #expect(try GitHub.decodePage(sample, pageSize: 100).hasMore == false)
}

private func fakeIssue(_ number: Int, hour: Int) throws -> Ping.Issue {
    let json = issueJSON(number, "Issue \(number)", state: "open", role: "NONE", login: "u")
        .replacingOccurrences(of: "2026-11-07T10:00:00Z", with: "2026-11-07T\(hour < 10 ? "0" : "")\(hour):00:00Z")
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(Ping.Issue.self, from: Data(json.utf8))
}

private func fakePage(_ issues: [Ping.Issue], hasMore: Bool) -> IssuePage {
    IssuePage(issues: issues, oldest: issues.last?.createdAt, hasMore: hasMore)
}

/// Busy repo A (2 pages, then empty) and quiet repo B (one page reaching far back).
private func fakeFeed() throws -> IssueFeed {
    let pages: [String: [IssuePage]] = [
        "a/a": [fakePage([try fakeIssue(5, hour: 20), try fakeIssue(4, hour: 18)], hasMore: true),
                fakePage([try fakeIssue(3, hour: 16), try fakeIssue(2, hour: 14)], hasMore: true),
                fakePage([], hasMore: false)],
        "b/b": [fakePage([try fakeIssue(9, hour: 19), try fakeIssue(8, hour: 10)], hasMore: false)],
    ]
    return IssueFeed { repo, page in
        guard let list = pages[repo] else { throw GitHubError("Repo not found, or it's private") }
        return list[page - 1]
    }
}

@Test func feedOnlyEverAppendsOlderIssues() async throws {
    let feed = try fakeFeed()
    await feed.reload(repos: ["a/a", "b/b"])
    let first = feed.visible.map(\.id)
    #expect(first == ["a/a#5", "b/b#9", "a/a#4"])           // b#8 (10:00) held back: a may have issues before it
    #expect(feed.hasMore)

    await feed.loadMore()
    let second = feed.visible.map(\.id)
    #expect(Array(second.prefix(first.count)) == first)      // nothing inserted above what was shown
    #expect(second == ["a/a#5", "b/b#9", "a/a#4", "a/a#3", "a/a#2"])

    await feed.loadMore()
    #expect(feed.visible.map(\.id).last == "b/b#8")          // a exhausted: b's oldest appears at the bottom
    #expect(feed.hasMore == false)
}

@Test func feedKeepsOtherReposWhenOneFails() async throws {
    let feed = try fakeFeed()
    await feed.reload(repos: ["b/b", "missing/repo"])
    #expect(feed.visible.map(\.id) == ["b/b#9", "b/b#8"])
    #expect(feed.failedRepos == ["missing/repo"])
    #expect(feed.errors["missing/repo"] == "Repo not found, or it's private")
}

// MARK: - For You

@Test func topLanguagesCountOwnReposOnly() {
    let repos = [
        UserRepo(language: "Swift", fork: false), UserRepo(language: "Swift", fork: false),
        UserRepo(language: "Python", fork: false), UserRepo(language: nil, fork: false),
        UserRepo(language: "Swift", fork: true), UserRepo(language: "Go", fork: true),
    ]
    let top = LanguageShare.top(from: repos)
    #expect(top.map(\.name) == ["Swift", "Python"])         // forks and unknown language skipped
    #expect(abs(top[0].share - 2.0 / 3.0) < 0.0001)
    #expect(LanguageShare.top(from: []).isEmpty)
    let many = ["A", "B", "C", "D", "E", "F"].map { UserRepo(language: $0, fork: false) }
    #expect(LanguageShare.top(from: many).map(\.name) == ["A", "B", "C", "D", "E"])  // ties A–Z, top 5
}

@Test(arguments: [
    ("dhruv-sharma29", "dhruv-sharma29"), ("@octocat", "octocat"),
    ("https://github.com/octocat/", "octocat"), (" a ", "a"),
])
func handleAccepts(input: String, expected: String) {
    #expect(GitHub.normalizeHandle(input) == expected)
}

@Test(arguments: ["", "-lead", "trail-", "dou--ble", "has space", "a/b", String(repeating: "a", count: 40)])
func handleRejects(input: String) {
    #expect(GitHub.normalizeHandle(input) == nil)
}

@Test func suggestionQueryAndSearchDecoding() throws {
    let query = GitHub.suggestionQuery(language: "Jupyter Notebook", excluding: "me", since: Date(timeIntervalSince1970: 1_794_045_600))
    #expect(query == #"is:issue is:open no:assignee label:"good first issue" language:"Jupyter Notebook" comments:<10 created:>=2026-11-07 -user:me"#)

    let json = #"{"total_count": 1, "items": [{"number": 3, "title": "Fix it", "state": "open", "created_at": "2026-11-07T10:00:00Z", "html_url": "https://github.com/o/r/issues/3", "author_association": "OWNER", "user": {"login": "o", "avatar_url": "https://avatars.githubusercontent.com/u/1"}, "repository_url": "https://api.github.com/repos/o/r"}]}"#
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let item = try #require(try decoder.decode(SearchResults.self, from: Data(json.utf8)).items.first)
    #expect(item.repo == "o/r")
    #expect(item.issue.role == .owner)
}

// MARK: - Explore

@Test func exploreQueryBuildsLanguageAndKeywords() {
    #expect(GitHub.exploreQuery(language: nil, text: "") == "is:issue is:open")
    #expect(GitHub.exploreQuery(language: "C++", text: "  crash on launch ") == #"is:issue is:open language:"C++" crash on launch"#)
}

@Test func searchStopsAtGitHubsThousandResultCap() throws {
    let one = #"{"number": 1, "title": "t", "state": "open", "created_at": "2026-11-07T10:00:00Z", "html_url": "https://github.com/o/r/issues/1", "author_association": "NONE", "user": {"login": "o", "avatar_url": "https://a.b/c"}, "repository_url": "https://api.github.com/repos/o/r"}"#
    func results(total: Int, count: Int) throws -> SearchResults {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let items = Array(repeating: one, count: count).joined(separator: ",")
        return try decoder.decode(SearchResults.self, from: Data(#"{"total_count": \#(total), "items": [\#(items)]}"#.utf8))
    }
    #expect(try results(total: 392_118, count: 30).hasMore(page: 1, perPage: 30))
    #expect(try results(total: 392_118, count: 30).hasMore(page: 34, perPage: 30) == false) // 1,020 > 1,000 cap
    #expect(try results(total: 45, count: 15).hasMore(page: 2, perPage: 30) == false)       // short last page
}

@Test func filterSummaryNamesActiveChoices() {
    #expect(IssueFilter().summary == "Filter")
    #expect(IssueFilter(state: .open, opener: .maintainers).summary == "Open · Maintainers")
    #expect(IssueFilter(repo: "swiftlang/swift-format").summary == "swift-format")
}

// MARK: - For You filters

@Test func suggestionFilterSurvivesSaving() {
    let custom = SuggestionFilter(label: .helpWanted, days: 7, maxComments: nil, unassignedOnly: false)
    #expect(SuggestionFilter(rawValue: custom.rawValue) == custom)
    #expect(SuggestionFilter(rawValue: SuggestionFilter().rawValue) == SuggestionFilter())
    #expect(SuggestionFilter(rawValue: "garbage") == nil)
}

@Test func suggestionFilterSummary() {
    #expect(SuggestionFilter().summary == "Filter")
    #expect(SuggestionFilter(label: .helpWanted, days: 7).summary == "Help wanted · Past week")
    #expect(SuggestionFilter(maxComments: nil, unassignedOnly: false).summary == "Any comments · Assigned too")
}

@Test func suggestionQueryFollowsFilter() {
    let day = Date(timeIntervalSince1970: 1_794_045_600)
    let loose = SuggestionFilter(label: .any, days: 30, maxComments: nil, unassignedOnly: false)
    #expect(GitHub.suggestionQuery(language: "Go", excluding: "me", since: day, filter: loose)
        == #"is:issue is:open language:"Go" created:>=2026-11-07 -user:me"#)
    let docs = SuggestionFilter(label: .documentation, maxComments: 5)
    #expect(GitHub.suggestionQuery(language: "Go", excluding: "me", since: day, filter: docs)
        == #"is:issue is:open no:assignee label:"documentation" language:"Go" comments:<5 created:>=2026-11-07 -user:me"#)
}

// MARK: - Staying under GitHub's rate limit

@Test func rateLimitResetFromHeaders() {
    let now = Date(timeIntervalSince1970: 1_000)
    func headers(_ values: [String: String]) -> (String) -> String? { { values[$0] } }
    #expect(RateLimit.resetDate(header: headers(["x-ratelimit-remaining": "0", "x-ratelimit-reset": "1600"]), now: now)
        == Date(timeIntervalSince1970: 1_600))
    #expect(RateLimit.resetDate(header: headers(["retry-after": "60"]), now: now) == Date(timeIntervalSince1970: 1_060))
    #expect(RateLimit.resetDate(header: headers(["x-ratelimit-remaining": "12", "x-ratelimit-reset": "1600"]), now: now) == nil)
    #expect(RateLimit.resource(for: "search/issues") == "search")
    #expect(RateLimit.resource(for: "repos/a/b/issues") == "core")
}

@Test func rateLimitBlocksUntilReset() {
    let now = Date.now
    RateLimit.block("test", until: now.addingTimeInterval(60))
    #expect(RateLimit.blockedUntil("test", now: now) != nil)
    #expect(RateLimit.blockedUntil("test", now: now.addingTimeInterval(61)) == nil)
    #expect(RateLimit.blockedUntil("other", now: now) == nil)
}

@Test func starCacheRefetchesAfterADay() {
    let now = Date(timeIntervalSince1970: 1_000_000)
    let cache = StarCache(entries: [
        "fresh/repo": .init(stars: 5, fetched: now.addingTimeInterval(-60 * 60)),
        "stale/repo": .init(stars: 9, fetched: now.addingTimeInterval(-25 * 60 * 60)),
        "old/repo": .init(stars: 1, fetched: now.addingTimeInterval(-8 * 24 * 60 * 60)),
    ])
    #expect(cache.needsFetch("fresh/repo", now: now) == false)
    #expect(cache.needsFetch("stale/repo", now: now))
    #expect(cache.needsFetch("never/seen", now: now))
    #expect(cache.pruned(now: now).entries.keys.sorted() == ["fresh/repo", "stale/repo"])
}

@Test func checksAtMostEveryFiveMinutesUnlessAsked() {
    let now = Date(timeIntervalSince1970: 1_000_000)
    #expect(Checker.shouldRun(lastRun: nil, now: now, force: false))
    #expect(Checker.shouldRun(lastRun: now.addingTimeInterval(-60), now: now, force: false) == false)
    #expect(Checker.shouldRun(lastRun: now.addingTimeInterval(-5 * 60), now: now, force: false))
    #expect(Checker.shouldRun(lastRun: now.addingTimeInterval(-60), now: now, force: true))
}

@Test func cleanTokenTrimsAndRejectsJunk() {
    let fake = "github_pat_" + String(repeating: "x", count: 30) // made-up, not a real token
    #expect(GitHub.cleanToken("  \(fake)\n") == fake)
    #expect(GitHub.cleanToken("short") == nil)
    #expect(GitHub.cleanToken("has a space in it but is long enough") == nil)
    #expect(GitHub.cleanToken("") == nil)
}
