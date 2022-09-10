import Foundation

struct GetStatusRequest: Request {
    typealias Response = Status

    let method: HttpMethod = .get
    let path: String

    init(id: String) {
        path = "/statuses/\(id)"
    }
}
