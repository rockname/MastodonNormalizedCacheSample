import Foundation
import SwiftSoup

struct Account: Decodable, Equatable, Hashable {
    typealias ID = String

    let id: ID
    let displayName: String
    let note: String
    let avatar: String
    let createdAt: Date
    let statusesCount: Int
    let followersCount: Int
    let followingCount: Int

    var normalizedNote: String {
        (try? SwiftSoup.parse(note).text()) ?? ""
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case note
        case avatar
        case createdAt = "created_at"
        case statusesCount = "statuses_count"
        case followersCount = "followers_count"
        case followingCount = "following_count"
    }
}
