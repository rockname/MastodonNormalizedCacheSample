import Foundation

struct GetAccountCredentialRequest: Request {
    typealias Response = Account

    let method: HttpMethod = .get
    let path = "/accounts/verify_credentials"
}
