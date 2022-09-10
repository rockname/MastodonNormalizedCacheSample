import CoreData
import Combine

struct CoreDataModelPublisher<Model: CoreDataModel & NSManagedObject>: Publisher {
    typealias Output = [Model.Entity]
    typealias Failure = Never

    let context: NSManagedObjectContext
    let fetchRequest: NSFetchRequest<Model>
    let combinePublisher: ((AnyPublisher<[Model.Entity], Never>) -> AnyPublisher<[Model.Entity], Never>)?

    init(
        context: NSManagedObjectContext,
        fetchRequest: NSFetchRequest<Model>,
        combinePublisher: ((AnyPublisher<[Model.Entity], Never>) -> AnyPublisher<[Model.Entity], Never>)? = nil
    ) {
        self.context = context
        self.fetchRequest = fetchRequest
        self.combinePublisher = combinePublisher
    }

    func receive<S>(subscriber: S) where S: Subscriber, S.Input == Output, S.Failure == Failure {
        do {
            let subscription = try CoreDataModelSubscription(
                subscriber: subscriber,
                context: context,
                fetchRequest: fetchRequest,
                combinePublisher: combinePublisher
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
        combinePublisher: ((AnyPublisher<[Model.Entity], Never>) -> AnyPublisher<[Model.Entity], Never>)?
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
        if let combinePublisher = combinePublisher {
            publisher = combinePublisher(publisher)
        }
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
