import Foundation

/// The two fields of a user's repo that language ranking needs.
struct UserRepo: Decodable {
    let language: String?
    let fork: Bool
}
