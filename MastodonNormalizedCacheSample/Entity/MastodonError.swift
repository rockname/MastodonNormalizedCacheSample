import Foundation

struct MastodonError: Error, Decodable {
    struct Reason: Decodable {
        let error: MastodonError
        let description: String

        private enum CodingKeys: String, CodingKey {
            case error
            case description
        }
    }

    struct Detail: Decodable {
        let username: [Reason]?
        let email: [Reason]?
        let password: [Reason]?
        let agreement: [Reason]?
        let locale: [Reason]?
        let reason: [Reason]?

        private enum CodingKeys: String, CodingKey {
            case username
            case email
            case password
            case agreement
            case locale
            case reason
        }
    }

    let error: String
    let errorDescription: String?
    let details: Detail?

    private enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
        case details
    }
}
