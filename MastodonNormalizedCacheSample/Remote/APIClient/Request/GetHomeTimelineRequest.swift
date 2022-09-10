import Foundation

struct GetHomeTimelineRequest: Request {
    typealias Response = [Status]

    let method: HttpMethod = .get
    let path = "/timelines/home"

    let queryParameters: [String : String]?

    init(
        maxID: Status.ID? = nil,
        sinceID: Status.ID? = nil,
        minID: Status.ID? = nil,
        limit: Int? = nil,
        local: Bool? = nil
    ) {
        queryParameters = [
            "max_id": maxID,
            "since_id": sinceID,
            "min_id": minID,
            "limit": limit.map { "\($0)" },
            "local": local.map { $0 ? "true" : "false" }
        ]
            .compactMapValues { $0 }
    }
}
