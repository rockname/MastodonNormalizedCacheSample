import Foundation
import Combine

struct AuthenticationRepository {
    let apiClient: APIClient = .init()
    let authenticationStore: AuthenticationStore = .shared
    let currentAccountIDStore: CurrentAccountIDStore = .init()

    var isLoggedIn: Bool {
        authenticationStore.isLoggedIn
    }

    func createApplication() async throws -> Application {
        try await apiClient.send(PostApplicationRequest())
    }

    func constructAuthorizeURL(with application: Application) -> URL? {
        let domain = "mstdn.jp"
        let oauthEndpointURL = URL(string: "https://" + domain + "/oauth/")!
        let authorizeEndpointURL = oauthEndpointURL.appendingPathComponent("authorize")

        guard var components = URLComponents(string: authorizeEndpointURL.absoluteString) else {
            return nil
        }

        var items: [URLQueryItem] = []
        items.append(URLQueryItem(name: "response_type", value: "code"))
        items.append(URLQueryItem(name: "client_id", value: application.clientID))
        items.append(URLQueryItem(name: "redirect_uri", value: application.redirectURI))
        items.append(URLQueryItem(name: "scope", value: "read write follow push"))
        components.queryItems = items

        return components.url
    }

    func authenticate(application: Application, code: String) async throws {
        let request = PostOAuthTokenRequest(
            clientID: application.clientID!,
            clientSecret: application.clientSecret!,
            redirectURI: application.redirectURI!,
            code: code,
            grantType: "authorization_code"
        )
        let token = try await apiClient.send(request)
        try authenticationStore.save(Authentication(accessToken: token.accessToken))
        let credential = try await apiClient.send(GetAccountCredentialRequest())
        currentAccountIDStore.save(credential.id)
    }

    func watchAuthentication() -> AnyPublisher<Authentication?, Never> {
        authenticationStore.authenticationChangeEvent
    }

    func logout() throws {
        currentAccountIDStore.delete()
        try authenticationStore.delete()
    }
}
