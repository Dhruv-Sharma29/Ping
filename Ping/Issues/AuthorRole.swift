import Foundation

/// How the person who opened an issue relates to the repo (GitHub's `author_association`).
enum AuthorRole: String, Decodable {
    case owner = "OWNER"
    case member = "MEMBER"
    case collaborator = "COLLABORATOR"
    case contributor = "CONTRIBUTOR"
    case firstTimeContributor = "FIRST_TIME_CONTRIBUTOR"
    case firstTimer = "FIRST_TIMER"
    case mannequin = "MANNEQUIN"
    case none = "NONE"

    /// GitHub may add values; an unknown one shouldn't make the whole issue list fail to load.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = AuthorRole(rawValue: raw) ?? .none
    }

    var label: String {
        switch self {
        case .owner: "Owner"
        case .member: "Member"
        case .collaborator: "Collaborator"
        case .contributor: "Contributor"
        case .firstTimeContributor: "First-time contributor"
        case .firstTimer: "New to GitHub"
        case .mannequin: "Imported user"
        case .none: "No association"
        }
    }

    /// People who can usually triage or merge: highlighted so they stand out in the list.
    var isMaintainer: Bool { self == .owner || self == .member || self == .collaborator }
}
