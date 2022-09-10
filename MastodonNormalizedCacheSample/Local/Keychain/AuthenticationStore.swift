import Foundation
import KeychainAccess
import Combine

class AuthenticationStore {
    private enum Constants {
        static let accessTokenKey = "access_token"
    }

    static let shared = AuthenticationStore()

    private let _authenticationChangeEvent = PassthroughSubject<Authentication?, Never>()
    var authenticationChangeEvent: AnyPublisher<Authentication?, Never> {
        _authenticationChangeEvent.eraseToAnyPublisher()
    }

    var isLoggedIn: Bool {
        (try? load()) != nil
    }

    private let keychain: Keychain

    private init(service: String = "com.rockname.MastodonSample") {
        keychain = Keychain(service: service)
    }

    func save(_ authentication: Authentication) throws {
        try keychain.set(authentication.accessToken, key: Constants.accessTokenKey)
        _authenticationChangeEvent.send(authentication)
    }

    func load() throws -> Authentication? {
        try keychain.get(Constants.accessTokenKey).map(Authentication.init(accessToken:))
    }

    func delete() throws {
        try keychain.remove(Constants.accessTokenKey)
        _authenticationChangeEvent.send(nil)
    }
}
