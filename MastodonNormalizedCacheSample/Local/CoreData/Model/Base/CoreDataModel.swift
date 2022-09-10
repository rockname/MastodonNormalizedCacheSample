import Foundation

protocol CoreDataModel {
    associatedtype Entity: Equatable
    func update(with entity: Entity)
    func toEntity() -> Entity
}
