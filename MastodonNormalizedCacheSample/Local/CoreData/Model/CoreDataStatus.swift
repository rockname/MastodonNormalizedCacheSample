import Foundation

extension CoreDataStatus: CoreDataModel {
    typealias Entity = Status

    func update(with entity: Entity) {
        id = entity.id
        account = CoreDataAccount(context: managedObjectContext!)
        account!.update(with: entity.account)
        content = entity.content
        url = entity.url
        favoritesCount = Int64(entity.favouritesCount)
        favorited = entity.favourited!
        createdAt = entity.createdAt
    }

    func toEntity() -> Entity {
        Status(
            id: id!,
            account: account!.toEntity(),
            content: content,
            url: url,
            favouritesCount: Int(favoritesCount),
            favourited: favorited,
            createdAt: createdAt!
        )
    }
}
