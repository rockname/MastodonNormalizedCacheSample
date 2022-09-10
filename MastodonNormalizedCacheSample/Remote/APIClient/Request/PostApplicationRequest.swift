import Foundation

struct PostApplicationRequest: Request {
    typealias Response = Application

    let method: HttpMethod = .post
    let path = "/apps"

    let queryParameters: [String : String]?

    init(
        clientName: String = "rockname-mastodon-sample",
        redirectURIs: String = "rockname-mastodon-sample://mstdn.jp/oauth",
        scopes: String = "read write follow push"
    ) {
        queryParameters = [
            "client_name": clientName,
            "redirect_uris": redirectURIs,
            "scopes": scopes
        ]
    }
}
