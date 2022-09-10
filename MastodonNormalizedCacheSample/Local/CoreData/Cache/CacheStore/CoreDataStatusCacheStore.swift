import Foundation
import CoreData
import Combine

class CoreDataStatusCacheStore {
    private let coreDataStore: CoreDataStore

    init(coreDataStore: CoreDataStore = .shared) {
        self.coreDataStore = coreDataStore
    }

    func store(_ status: Status) async throws {
        let context = coreDataStore.makeBackgroundContext()
        try await context.perform {
            let coreDataStatus = CoreDataStatus(context: context)
            coreDataStatus.update(with: status)
            try context.save()
        }
    }

    func store(_ statuses: [Status]) async throws {
        let context = coreDataStore.makeBackgroundContext()
        try await context.perform {
            statuses.forEach { status in
                let coreDataStatus = CoreDataStatus(context: context)
                coreDataStatus.update(with: status)
            }
            try context.save()
        }
    }

    func watch(by cacheKey: TimelineCacheKey) -> AnyPublisher<[Status], Never> {
        let fetchRequest = CoreDataStatus.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CoreDataStatus.createdAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "id in %@", cacheKey.statusCacheKeys.map { $0.statusID })
        let accountsFetchRequest = CoreDataAccount.fetchRequest()
        accountsFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CoreDataAccount.createdAt, ascending: false)]
        accountsFetchRequest.predicate = NSPredicate(format: "id in %@", cacheKey.statusCacheKeys.map { $0.accountCacheKey.accountID })
        let accountsPublisher = CoreDataModelPublisher(
            context: coreDataStore.viewContext,
            fetchRequest: accountsFetchRequest
        )
        return CoreDataModelPublisher(
            context: coreDataStore.viewContext,
            fetchRequest: fetchRequest,
            combinePublisher: { statusesPublisher in
                statusesPublisher
                    .combineLatest(accountsPublisher)
                    .map { statuses, accounts in
                        statuses.combined(with: accounts)
                    }
                    .eraseToAnyPublisher()
            }
        ).eraseToAnyPublisher()
    }

    func watch(by cacheKey: StatusCacheKey) -> AnyPublisher<Status, Never> {
        let fetchRequest = CoreDataStatus.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CoreDataStatus.createdAt, ascending: false)]
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "id = %@", cacheKey.statusID)
        let accountsFetchRequest = CoreDataAccount.fetchRequest()
        accountsFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CoreDataAccount.createdAt, ascending: false)]
        accountsFetchRequest.fetchLimit = 1
        accountsFetchRequest.predicate = NSPredicate(format: "id = %@", cacheKey.accountCacheKey.accountID)
        let accountsPublisher = CoreDataModelPublisher(
            context: coreDataStore.viewContext,
            fetchRequest: accountsFetchRequest
        )
        return CoreDataModelPublisher(
            context: coreDataStore.viewContext,
            fetchRequest: fetchRequest,
            combinePublisher: { statusesPublisher in
                statusesPublisher
                    .combineLatest(accountsPublisher)
                    .map { statuses, accounts in
                        statuses.combined(with: accounts)
                    }
                    .eraseToAnyPublisher()
            }
        )
        .compactMap { $0.first }
        .eraseToAnyPublisher()
    }
}

private extension Array where Element == Status {
    func combined(with accounts: [Account]) -> [Status] {
        let accountDict = accounts.reduce([Account.ID: Account]()) { partialResult, account in
            var result = partialResult
            result[account.id] = account
            return result
        }
        return self.map { status in
            var status = status
            if let account = accountDict[status.account.id] {
                status.account = account
            }
            return status
        }
    }
}
