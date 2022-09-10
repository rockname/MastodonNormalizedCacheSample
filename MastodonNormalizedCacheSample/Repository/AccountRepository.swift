import Foundation
import Combine

struct AccountRepository {
    let apiClient: APIClient = .init()
    let accountCacheStore: CoreDataAccountCacheStore = .init()
    let cacheKeyStore: InMemoryCacheKeyStore<AccountCacheKey> = .init()

    func fetchMyAccount() async throws {
        let response = try await apiClient.send(GetAccountCredentialRequest())
        try await accountCacheStore.store(response)
        cacheKeyStore.store(.init(accountID: response.id))
    }

    func updateAccount(displayName: String, note: String?) async throws {
        let response = try await apiClient.send(PatchAccountCredentialRequest(displayName: displayName, note: note))
        try await accountCacheStore.store(response)
    }

    func watch() -> AnyPublisher<Account, Never> {
        cacheKeyStore.cacheKey
            .map { cacheKey in
                accountCacheStore.watch(by: cacheKey)
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
}
