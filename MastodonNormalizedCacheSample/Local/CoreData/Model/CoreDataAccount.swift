import Foundation

extension CoreDataAccount: CoreDataModel {
    typealias Entity = Account

    func update(with entity: Entity) {
        id = entity.id
        displayName = entity.displayName
        avatar = entity.avatar
        createdAt = entity.createdAt
        followersCount = Int64(entity.followersCount)
        followingCount = Int64(entity.followingCount)
        note = entity.note
        statusesCount = Int64(entity.statusesCount)
    }

    func toEntity() -> Account {
        Account(
            id: id!,
            displayName: displayName!,
            note: note!,
            avatar: avatar!,
            createdAt: createdAt!,
            statusesCount: Int(statusesCount),
            followersCount: Int(followersCount),
            followingCount: Int(followingCount)
        )
    }
}
