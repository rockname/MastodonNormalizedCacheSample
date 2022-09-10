import Foundation
import SwiftSoup

struct Status: Decodable, Equatable, Identifiable {
    typealias ID = String

    let id: ID
    var account: Account
    let content: String?
    let url: String?
    let favouritesCount: Int
    let favourited: Bool?
    let createdAt: Date

    var formattedCreatedAt: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: createdAt)
    }

    var normalizedContent: String? {
        content.flatMap { try? SwiftSoup.parse($0).text() }
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case account
        case content
        case url
        case favouritesCount = "favourites_count"
        case favourited
        case createdAt = "created_at"
    }
}
