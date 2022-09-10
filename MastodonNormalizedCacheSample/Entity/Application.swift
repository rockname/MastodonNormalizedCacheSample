import Foundation

struct Application: Decodable {
    let name: String
    let website: String?
    let vapidKey: String?
    let redirectURI: String?
    let clientID: String?
    let clientSecret: String?

    private enum CodingKeys: String, CodingKey {
        case name
        case website
        case vapidKey = "vapid_key"
        case redirectURI = "redirect_uri"
        case clientID = "client_id"
        case clientSecret = "client_secret"
    }
}
