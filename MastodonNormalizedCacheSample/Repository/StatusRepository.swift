import Foundation
import Combine

struct StatusRepository {
    let apiClient: APIClient = .init()
    let statusCacheStore: CoreDataStatusCacheStore = .init()
    let cacheKeyStore: InMemoryCacheKeyStore<StatusCacheKey> = .init()

    func fetchStatus(by id: Status.ID) async throws {
        let response = try await apiClient.send(GetStatusRequest(id: id))
        try await statusCacheStore.store(response)
        cacheKeyStore.store(.init(statusID: response.id, accountCacheKey: .init(accountID: response.account.id)))
    }

    func favoriteStatus(by id: Status.ID) async throws {
        let response = try await apiClient.send(PostStatusFavoriteRequest(id: id))
        try await statusCacheStore.store(response)
    }

    func unfavoriteStatus(by id: Status.ID) async throws {
        let response = try await apiClient.send(PostStatusUnfavoriteRequest(id: id))
        try await statusCacheStore.store(response)
    }

    func watch() -> AnyPublisher<Status, Never> {
        cacheKeyStore.cacheKey
            .map { cacheKey in
                statusCacheStore.watch(by: cacheKey)
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
}
