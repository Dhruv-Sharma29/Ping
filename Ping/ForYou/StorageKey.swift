/// `@AppStorage` keys shared by several screens. None of these are secrets.
enum StorageKey {
    static let handle = "githubHandle"
    static let preferredLanguages = "preferredLanguages" // newline-separated, in the order picked
    static let suggestionFilter = "suggestionFilter"
    static let exploreLanguage = "exploreLanguage"
    static let hasToken = "hasGitHubToken" // only whether one exists; the token lives in the Keychain
    static let detectedLanguages = "detectedLanguages" // newline-separated; cached from the user's repos
}
