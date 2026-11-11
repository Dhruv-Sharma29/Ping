import Foundation
import Security

/// The optional GitHub token. Kept only in the iOS Keychain: never in UserDefaults, code, URLs or logs.
/// A plain "has a token" flag goes to UserDefaults so the UI can react; the token itself never does.
enum TokenStore {
    private static let service = "com.dhruvsharma.Ping"
    private static let account = "github-token"
    private static var cached: String?? // outer nil = Keychain not read yet

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    static var token: String? {
        if let cached { return cached }
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let value = SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess
            ? (result as? Data).flatMap { String(data: $0, encoding: .utf8) }
            : nil
        cached = .some(value)
        return value
    }

    /// Readable after the first unlock since boot, so background checks work while the phone is locked.
    /// "ThisDeviceOnly": never copied to other devices or backups.
    @discardableResult
    static func save(_ token: String) -> Bool {
        SecItemDelete(baseQuery as CFDictionary)
        var item = baseQuery
        item[kSecValueData as String] = Data(token.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let saved = SecItemAdd(item as CFDictionary, nil) == errSecSuccess
        cached = .some(saved ? token : nil)
        UserDefaults.standard.set(saved, forKey: StorageKey.hasToken)
        return saved
    }

    static func delete() {
        SecItemDelete(baseQuery as CFDictionary)
        cached = .some(nil)
        UserDefaults.standard.set(false, forKey: StorageKey.hasToken)
    }
}
