# MastodonNormalizedCacheSample
This is a mastodon sample SwiftUI app.<br/>
This app is implemented with the architecture of state management with normalized cache.

| Home | Detail | Profile |
| -- | -- | -- |
| ![](https://user-images.githubusercontent.com/8536870/189512478-557a8d30-45f9-41f0-9d3a-2988929a55f0.png) | ![](https://user-images.githubusercontent.com/8536870/189512480-57dc1acf-caac-476b-8e4d-ef0b0100683d.png) | ![](https://user-images.githubusercontent.com/8536870/189512477-c78bc70a-62fc-4b8f-971f-78af2a8428ee.png) |

## Requirements
Xcode 14 beta 1+ <br/>
iOS 16.0+

## Motivation

If you develop an iOS app for mastodon, for example, you need to make sure that no matter which screen you use to perform a favorite action on a post, the same post on all screens should reflect the same state.
The same is true for other mutations, such as updating profile information.

To prevent data inconsistencies, a good solution is to hoist up the states that require synchronization as Global State and propagate them to each screen, rather than managing them separately on each screen.

![](https://user-images.githubusercontent.com/8536870/189909897-220a3cf7-ef90-4bd6-a55d-6eaadd80cd6c.png)

The Single Store architecture such as [Redux](https://redux.js.org/) is well known as a method of managing Global State.

![](https://user-images.githubusercontent.com/8536870/189910601-de3f0d60-6319-4c8b-9382-f1ad2e3676c1.png)

But it is an overkill architecture when most of the state to be managed is Server State, such as responses from the server.

![](https://user-images.githubusercontent.com/8536870/189915150-a7b1c3e5-f9af-4cb8-a28a-fe3a977b1708.png)

## Solution

In order to meet these requirements, the architecture of state management with **Normalized Cache** is adopted.<br/>
A GraphQL Client library such as [Apollo Client](https://www.apollographql.com/apollo-client) and [Relay](https://relay.dev/) provides this functionality.

![](https://user-images.githubusercontent.com/8536870/189913270-f348277f-0140-4c33-82e2-49f2eab754f9.png)

Normalized Cache is that splitting the data retrieved from the server into individual objects, assign a logically unique identifier to each object, and store them in a flat data structure.

![](https://user-images.githubusercontent.com/8536870/189914659-996d4534-4d8f-414e-83a2-5b64e946a6e3.png)

This allows, for example, in the case of the mastodon application shown in the previous example, favorite actions on a post object will be properly updated by a single uniquely managed post object, so that they can be reflected in the UI of each screen without inconsistencies.

## Detail

This section describes the detailed implementation in developing a mastodon iOS app adopting the state management architecture with Normalized Cache.

First, mastodon's API is defined as REST API, not GraphQL.
Therefore, it is not possible to use Normalized Cache with a library such as Apollo Client.

So this time, we will use the [Core Data](https://developer.apple.com/documentation/coredata) database to cache the data fetched from the REST API.

### Core Data

First, create a `CoreDataStore` shared class to hold the Persistence Container for Core Data.

```swift
class CoreDataStore {
    static let shared = CoreDataStore()

    lazy private var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Mastodon")
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    private init() {
    }

    func makeBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        return context
    }
}
```

Core Data is used only for state management purposes, so applying **In-memory** database setting.

```diff
lazy private var container: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "Mastodon")
+   guard let description = container.persistentStoreDescriptions.first else {
+       fatalError("Failed to retrieve a persistent store description.")
+   }
+   
+   description.url = URL(fileURLWithPath: "/dev/null")
    container.loadPersistentStores { storeDescription, error in
        if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
        }
    }
    return container
}()
```

Next, add a Core Data Model corresponding to `Status`, an object representing a post, and `Account`, an object representing a user in the mastodon.<br/>
And set up a relationship from Status to Account.

![](https://user-images.githubusercontent.com/8536870/190175035-fdfe4354-4050-4ed1-b52f-8174ca53ac02.png)

Also, to prevent duplicate of the same object, set constraints for these model's primary key.

![](https://user-images.githubusercontent.com/8536870/190175107-c50a884e-72b2-4724-9e78-3b65dec29c62.png)

Then set the merge policy to `NSMergeByPropertyObjectTrumpMergePolicy`. This will cause the data to be overwritten and saved if the same object with the primary key is saved.

```diff
class CoreDataStore {
    static let shared = CoreDataStore()

    lazy private var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Mastodon")
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }

        description.url = URL(fileURLWithPath: "/dev/null")
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
+       container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    private init() {
    }

    func makeBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
+       context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}
```

Now that the preparations around Core Data are done, create a `CoreDataStatusCacheStore` class to cache `Status`.<br/>
Execute the process of writing to Core Data using the Background Context.

```swift
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
}
```

Let's add the implementation around change monitoring on Core Data.

Core Data allows you to monitor changes to data on Core Data using [NSFetchedResultsControllerDelegate](https://developer.apple.com/documentation/coredata/nsfetchedresultscontrollerdelegate).

So we will create a custom Publisher containing this monitoring process.

```swift
protocol CoreDataModel {
    associatedtype Entity: Equatable
    func toEntity() -> Entity
}

struct CoreDataModelPublisher<Model: CoreDataModel & NSManagedObject>: Publisher {
    typealias Output = [Model.Entity]
    typealias Failure = Never

    let context: NSManagedObjectContext
    let fetchRequest: NSFetchRequest<Model>

    init(
        context: NSManagedObjectContext,
        fetchRequest: NSFetchRequest<Model>
    ) {
        self.context = context
        self.fetchRequest = fetchRequest
    }

    func receive<S>(subscriber: S) where S: Subscriber, S.Input == Output, S.Failure == Failure {
        do {
            let subscription = try CoreDataModelSubscription(
                subscriber: subscriber,
                context: context,
                fetchRequest: fetchRequest
            )
            subscriber.receive(subscription: subscription)
        } catch {
            subscriber.receive(completion: .finished)
        }
    }
}

class CoreDataModelSubscription<
    S: Subscriber,
    Model: CoreDataModel & NSManagedObject
>: NSObject, NSFetchedResultsControllerDelegate, Subscription where S.Input == [Model.Entity], S.Failure == Never {
    private let controller: NSFetchedResultsController<Model>
    private let entitiesSubject: CurrentValueSubject<[Model.Entity], Never>
    private var cancellable: AnyCancellable?

    init(
        subscriber: S,
        context: NSManagedObjectContext,
        fetchRequest: NSFetchRequest<Model>
    ) throws {
        entitiesSubject = CurrentValueSubject((try context.fetch(fetchRequest)).map { $0.toEntity() })
        controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        super.init()
        controller.delegate = self
        try controller.performFetch()
        var publisher = entitiesSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
        cancellable = publisher
            .subscribe(on: DispatchQueue.global())
            .sink { entities in
                _ = subscriber.receive(entities)
            }
    }

    func request(_ demand: Subscribers.Demand) {}

    func cancel() {
        cancellable = nil
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith diff: CollectionDifference<NSManagedObjectID>
    ) {
        guard let models = controller.fetchedObjects as? [Model] else {
            return
        }

        entitiesSubject.send(models.map { $0.toEntity() })
    }
}
```

All that remains is to add a method that returns this custom Publisher into `CoreDataStatusCacheStore`.<br/>
The Core Data writing process was done in the Background Context, but the reading process is done in the View Context.

```swift
class CoreDataStatusCacheStore {
    ...
    func watch(by cacheKey: TimelineCacheKey) -> AnyPublisher<[Status], Never> {
        let fetchRequest = CoreDataStatus.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CoreDataStatus.createdAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "id in %@", cacheKey.statusCacheKeys.map { $0.statusID })
        return CoreDataModelPublisher(
            context: coreDataStore.viewContext,
            fetchRequest: fetchRequest
        ).eraseToAnyPublisher()
    }

    func watch(by cacheKey: StatusCacheKey) -> AnyPublisher<Status, Never> {
        let fetchRequest = CoreDataStatus.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CoreDataStatus.createdAt, ascending: false)]
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "id = %@", cacheKey.statusID)
        return CoreDataModelPublisher(
            context: coreDataStore.viewContext,
            fetchRequest: fetchRequest
        )
        .compactMap { $0.first }
        .eraseToAnyPublisher()
    }
}
```

There are two points to note here.

One is that changes in the Background Context must be merged into the View Context.<br/>
If this is not done, the `NSFetchedResultsControllerDelegate` that is fetching in the View Context will NOT be notified of the change.

To resolve this problem, extract the relevant changes by parsing the store’s Persistent History, then merge them into the view context. For more information on persistent history tracking, see [Consuming Relevant Store Changes](https://developer.apple.com/documentation/coredata/consuming_relevant_store_changes).

```diff
class CoreDataStore {
    static let shared = CoreDataStore()

+   private var notificationToken: NSObjectProtocol?
+   private var lastToken: NSPersistentHistoryToken?

    lazy private var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Mastodon")
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }

        description.url = URL(fileURLWithPath: "/dev/null")
+       description.setOption(
+           true as NSNumber,
+           forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
+       )
+       description.setOption(
+           true as NSNumber,
+           forKey: NSPersistentHistoryTrackingKey
+       )
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    private init() {
+       notificationToken = NotificationCenter.default.addObserver(forName: .NSPersistentStoreRemoteChange, object: nil, queue: nil) { note in
+           Task {
+               await self.fetchPersistentHistory()
+           }
+       }
    }

    func makeBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
+
+   private func fetchPersistentHistory() async {
+       do {
+           try await fetchPersistentHistoryTransactionsAndChanges()
+       } catch {
+           print("\(error.localizedDescription)")
+       }
+   }
+
+   private func fetchPersistentHistoryTransactionsAndChanges() async throws {
+       let taskContext = makeBackgroundContext()
+       taskContext.name = "persistentHistoryContext"
+
+       try await taskContext.perform {
+           let changeRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: self.lastToken)
+           let historyResult = try taskContext.execute(changeRequest) as? NSPersistentHistoryResult
+           if let history = historyResult?.result as? [NSPersistentHistoryTransaction],
+              !history.isEmpty {
+               self.mergePersistentHistoryChanges(from: history)
+               return
+           }
+           throw CoreDataError.persistentHistoryChangeError
+       }
+   }
+
+   private func mergePersistentHistoryChanges(from history: [NSPersistentHistoryTransaction]) {
+       let viewContext = viewContext
+       viewContext.perform {
+           for transaction in history {
+               viewContext.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
+               self.lastToken = transaction.token
+           }
+       }
+   }
}
```

Another point to note is that `NSFetchedResultsControllerDelegate` cannot monitor relationship changes.<br/>
That is, if the `username` of an `Account` associated with a `Status` is changed, the `NSFetchedResultsControllerDelegate` will NOT receive notification of the change.

Therefore, we need to implement an additional relationship monitoring process.

To do so, make a `CoreDataModelPublisher` combinable another `CoreDataModelPublisher`.

```diff
struct CoreDataModelPublisher<Model: CoreDataModel & NSManagedObject>: Publisher {
    typealias Output = [Model.Entity]
    typealias Failure = Never

    let context: NSManagedObjectContext
    let fetchRequest: NSFetchRequest<Model>
+   let combinePublisher: ((AnyPublisher<[Model.Entity], Never>) -> AnyPublisher<[Model.Entity], Never>)?

    init(
        context: NSManagedObjectContext,
        fetchRequest: NSFetchRequest<Model>,
+       combinePublisher: ((AnyPublisher<[Model.Entity], Never>) -> AnyPublisher<[Model.Entity], Never>)? = nil
    ) {
        self.context = context
        self.fetchRequest = fetchRequest
+       self.combinePublisher = combinePublisher
    }

    func receive<S>(subscriber: S) where S: Subscriber, S.Input == Output, S.Failure == Failure {
        do {
            let subscription = try CoreDataModelSubscription(
                subscriber: subscriber,
                context: context,
                fetchRequest: fetchRequest,
+               combinePublisher: combinePublisher
            )
            subscriber.receive(subscription: subscription)
        } catch {
            subscriber.receive(completion: .finished)
        }
    }
}

class CoreDataModelSubscription<
    S: Subscriber,
    Model: CoreDataModel & NSManagedObject
>: NSObject, NSFetchedResultsControllerDelegate, Subscription where S.Input == [Model.Entity], S.Failure == Never {
    private let controller: NSFetchedResultsController<Model>
    private let entitiesSubject: CurrentValueSubject<[Model.Entity], Never>
    private var cancellable: AnyCancellable?

    init(
        subscriber: S,
        context: NSManagedObjectContext,
        fetchRequest: NSFetchRequest<Model>,
+       combinePublisher: ((AnyPublisher<[Model.Entity], Never>) -> AnyPublisher<[Model.Entity], Never>)?
    ) throws {
        entitiesSubject = CurrentValueSubject((try context.fetch(fetchRequest)).map { $0.toEntity() })
        controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        super.init()
        controller.delegate = self
        try controller.performFetch()
        var publisher = entitiesSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
+       if let combinePublisher = combinePublisher {
+           publisher = combinePublisher(publisher)
+       }
        cancellable = publisher
            .subscribe(on: DispatchQueue.global())
            .sink { entities in
                _ = subscriber.receive(entities)
            }
    }

    func request(_ demand: Subscribers.Demand) {}

    func cancel() {
        cancellable = nil
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith diff: CollectionDifference<NSManagedObjectID>
    ) {
        guard let models = controller.fetchedObjects as? [Model] else {
            return
        }

        entitiesSubject.send(models.map { $0.toEntity() })
    }
}
```

After that, combine a Publisher monitoring an account relationship into a Publisher monitoring a status on `CoreDataStatusCacheStore.watch` method.

```diff
class CoreDataStatusCacheStore {
    ...
    func watch(by cacheKey: TimelineCacheKey) -> AnyPublisher<[Status], Never> {
        let fetchRequest = CoreDataStatus.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CoreDataStatus.createdAt, ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "id in %@", cacheKey.statusCacheKeys.map { $0.statusID })
+       let accountsFetchRequest = CoreDataAccount.fetchRequest()
+       accountsFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CoreDataAccount.createdAt, ascending: false)]
+       accountsFetchRequest.predicate = NSPredicate(format: "id in %@", cacheKey.statusCacheKeys.map { $0.accountCacheKey.accountID })
+       let accountsPublisher = CoreDataModelPublisher(
+           context: coreDataStore.viewContext,
+           fetchRequest: accountsFetchRequest
+       )
        return CoreDataModelPublisher(
            context: coreDataStore.viewContext,
            fetchRequest: fetchRequest,
+           combinePublisher: { statusesPublisher in
+               statusesPublisher
+                   .combineLatest(accountsPublisher)
+                   .map { statuses, accounts in
+                       statuses.combined(with: accounts)
+                   }
+                   .eraseToAnyPublisher()
+           }
+       ).eraseToAnyPublisher()
    }

    func watch(by cacheKey: StatusCacheKey) -> AnyPublisher<Status, Never> {
        let fetchRequest = CoreDataStatus.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CoreDataStatus.createdAt, ascending: false)]
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "id = %@", cacheKey.statusID)
+       let accountsFetchRequest = CoreDataAccount.fetchRequest()
+       accountsFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CoreDataAccount.createdAt, ascending: false)]
+       accountsFetchRequest.fetchLimit = 1
+       accountsFetchRequest.predicate = NSPredicate(format: "id = %@", cacheKey.accountCacheKey.accountID)
+       let accountsPublisher = CoreDataModelPublisher(
+           context: coreDataStore.viewContext,
+           fetchRequest: accountsFetchRequest
+       )
        return CoreDataModelPublisher(
            context: coreDataStore.viewContext,
            fetchRequest: fetchRequest,
+           combinePublisher: { statusesPublisher in
+               statusesPublisher
+                   .combineLatest(accountsPublisher)
+                   .map { statuses, accounts in
+                       statuses.combined(with: accounts)
+                   }
+                   .eraseToAnyPublisher()
+           }
       )
        .compactMap { $0.first }
        .eraseToAnyPublisher()
    }
}
```

Create a `CoreDataAccountCacheStore` to cache `Account` in the same way.

### Cache Key Store

Next, create an `InMemoryCacheKeyStore` class to store identifiers to be assigned to cache objects.

We provide a `cacheKey` property of type `AnyPublisher<CacheKey, Never>` so that we can monitor cache key changes.

```swift
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
```

For example, if you get the home timeline, the `CacheKey` to store would be an array of a Status ID.

### Repository

TBD

### UI

TBD

![](https://user-images.githubusercontent.com/8536870/190175937-d2d3a244-7d3b-459f-b81b-1580ca1b53d3.png)

