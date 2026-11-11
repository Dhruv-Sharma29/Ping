import Foundation

/// The body of a GitHub search response.
struct SearchResults: Decodable {
    let totalCount: Int
    let items: [SearchItem]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case items
    }

    /// GitHub serves at most the first 1,000 results of any search.
    func hasMore(page: Int, perPage: Int) -> Bool {
        items.count == perPage && page * perPage < min(totalCount, 1000)
    }
}
