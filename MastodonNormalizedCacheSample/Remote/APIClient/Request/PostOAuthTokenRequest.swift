import Foundation

struct PostOAuthTokenRequest: Request {
    typealias Response = Token

    var baseURL: URL { URL(string: "https://mstdn.jp")! }

    let method: HttpMethod = .post
    let path = "/oauth/token"

    let bodyParameters: BodyParameters?

    init(
        clientID: String,
        clientSecret: String,
        redirectURI: String,
        scope: String? = "read write follow push",
        code: String?,
        grantType: String
    ) {
        bodyParameters = PostOAuthTokenBodyParameters(
            clientID: clientID,
            clientSecret: clientSecret,
            redirectURI: redirectURI,
            scope: scope,
            code: code,
            grantType: grantType
        )
    }
}

private struct PostOAuthTokenBodyParameters: BodyParameters, Encodable {
    let clientID: String
    let clientSecret: String
    let redirectURI: String
    let scope: String?
    let code: String?
    let grantType: String

    private enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case clientSecret = "client_secret"
        case redirectURI = "redirect_uri"
        case scope
        case code
        case grantType = "grant_type"
    }
}
