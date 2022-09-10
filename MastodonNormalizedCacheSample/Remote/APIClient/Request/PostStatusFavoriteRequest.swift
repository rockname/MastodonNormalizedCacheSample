import Foundation

struct PostStatusFavoriteRequest: Request {
    typealias Response = Status

    let method: HttpMethod = .post
    let path: String

    init(id: String) {
        path = "/statuses/\(id)/favourite"
    }
}
