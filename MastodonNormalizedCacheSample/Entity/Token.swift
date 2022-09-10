import Foundation

struct Token: Decodable {
    let accessToken: String
    let tokenType: String
    let scope: String
    let createdAt: Date

    init(accessToken: String, tokenType: String, scope: String, createdAt: Date) {
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.scope = scope
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case createdAt = "created_at"
    }
}
