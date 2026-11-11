import Foundation
import SwiftData

@Model final class Repo {
    @Attribute(.unique) var name: String // "owner/repo"
    var lastSeen: Int? // highest issue number already handled; nil until the first check
    var lastChecked: Date?
    var error: String?

    init(name: String) { self.name = name }

    var owner: String { String(name.split(separator: "/").first ?? "") }
    var shortName: String { String(name.split(separator: "/").last ?? "") }
    var avatarURL: URL? { URL(string: "https://github.com/\(owner).png?size=96") }
}
