import Foundation

struct TimelineCacheKey: Equatable {
    let statusCacheKeys: [StatusCacheKey]
}
