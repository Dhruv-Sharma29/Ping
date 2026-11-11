import Foundation

struct GitHubError: LocalizedError {
    let errorDescription: String?
    init(_ message: String) { errorDescription = message }
}
