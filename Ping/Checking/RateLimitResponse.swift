/// The part of GET /rate_limit that Ping reads.
struct RateLimitResponse: Decodable {
    struct Resources: Decodable {
        let core: Bucket
    }

    struct Bucket: Decodable {
        let limit: Int
    }

    let resources: Resources
}
