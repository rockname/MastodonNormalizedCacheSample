import Foundation

struct GetAccountStatusesRequest: Request {
    typealias Response = [Status]

    let method: HttpMethod = .get
    let path: String

    let queryParameters: [String : String]?

    init(
        accountID: Account.ID,
        maxID: Status.ID? = nil,
        sinceID: Status.ID? = nil,
        limit: Int? = nil,
        excludeReplies: Bool? = true,
        excludeReblogs: Bool? = true
    ) {
        path = "/accounts/\(accountID)/statuses"
        queryParameters = [
            "max_id": maxID,
            "since_id": sinceID,
            "limit": limit.map { "\($0)" },
            "exclude_replies": excludeReplies.map { $0 ? "true" : "false" },
            "exclude_reblogs": excludeReblogs.map { $0 ? "true" : "false" }
        ]
            .compactMapValues { $0 }
    }
}
