import Foundation
import Combine

class InMemoryCacheKeyStore<CacheKey: Equatable> {
    private let _cacheKey = CurrentValueSubject<CacheKey?, Never>(nil)
    var cacheKey: AnyPublisher<CacheKey, Never> {
        _cacheKey.compactMap { $0 }.removeDuplicates().eraseToAnyPublisher()
    }
    var currentCacheKey: CacheKey? {
        _cacheKey.value
    }

    func store(_ cacheKey: CacheKey) {
        _cacheKey.send(cacheKey)
    }
}
