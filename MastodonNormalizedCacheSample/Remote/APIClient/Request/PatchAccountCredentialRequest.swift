import Foundation

struct PatchAccountCredentialRequest: Request {
    typealias Response = Account

    let method: HttpMethod = .patch
    let path = "/accounts/update_credentials"

    var bodyParameters: BodyParameters?

    init(
        displayName: String,
        note: String?
    ) {
        bodyParameters = PatchAccountCredentialBodyParameters(
            displayName: displayName,
            note: note
        )
    }
}

struct PatchAccountCredentialBodyParameters: BodyParameters, Encodable {
    let displayName: String
    let note: String?

    private enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case note
    }
}
