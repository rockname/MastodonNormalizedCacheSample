import Foundation

struct StatusCacheKey: Equatable {
    let statusID: Status.ID
    let accountCacheKey: AccountCacheKey
}
