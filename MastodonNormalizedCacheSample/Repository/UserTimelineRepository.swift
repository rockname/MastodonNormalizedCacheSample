import Foundation
import Combine

struct UserTimelineRepository {
    let accountID: Account.ID
    let apiClient: APIClient = .init()
    let statusCacheStore: CoreDataStatusCacheStore = .init()
    let cacheKeyStore: InMemoryCacheKeyStore<TimelineCacheKey> = .init()

    func fetchInitialTimeline() async throws {
        let response = try await apiClient.send(GetAccountStatusesRequest(accountID: accountID))
        try await statusCacheStore.store(response)
        cacheKeyStore.store(TimelineCacheKey(statusCacheKeys: response.map { status in
            StatusCacheKey(statusID: status.id, accountCacheKey: .init(accountID: status.account.id))
        }))
    }

    func fetchNextTimeline() async throws {
        guard
            let currentCacheKey = cacheKeyStore.currentCacheKey,
            let lastStatusID = currentCacheKey.statusCacheKeys.last?.statusID
        else { return }

        let response = try await apiClient.send(GetAccountStatusesRequest(accountID: accountID, maxID: lastStatusID))
        try await statusCacheStore.store(response)
        cacheKeyStore.store(
            TimelineCacheKey(
                statusCacheKeys: currentCacheKey.statusCacheKeys +
                    response.map { status in
                        StatusCacheKey(statusID: status.id, accountCacheKey: .init(accountID: status.account.id))
                    }
            )
        )
    }

    func favoriteStatus(by id: Status.ID) async throws {
        let response = try await apiClient.send(PostStatusFavoriteRequest(id: id))
        try await statusCacheStore.store(response)
    }

    func unfavoriteStatus(by id: Status.ID) async throws {
        let response = try await apiClient.send(PostStatusUnfavoriteRequest(id: id))
        try await statusCacheStore.store(response)
    }

    func watch() -> AnyPublisher<[Status], Never> {
        cacheKeyStore.cacheKey
            .map { cacheKey in
                statusCacheStore.watch(by: cacheKey)
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
}
