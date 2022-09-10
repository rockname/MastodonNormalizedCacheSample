import Foundation
import CoreData
import Combine

class CoreDataAccountCacheStore {
    private let coreDataStore: CoreDataStore

    init(coreDataStore: CoreDataStore = .shared) {
        self.coreDataStore = coreDataStore
    }

    func store(_ account: Account) async throws {
        let context = coreDataStore.makeBackgroundContext()
        try await context.perform {
            let coreDataAccount = CoreDataAccount(context: context)
            coreDataAccount.update(with: account)
            try context.save()
        }
    }

    func watch(by cacheKey: AccountCacheKey) -> AnyPublisher<Account, Never> {
        let fetchRequest = CoreDataAccount.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CoreDataAccount.createdAt, ascending: false)]
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "id = %@", cacheKey.accountID)
        return CoreDataModelPublisher(
            context: coreDataStore.viewContext,
            fetchRequest: fetchRequest
        )
        .compactMap { $0.first }
        .eraseToAnyPublisher()
    }
}
