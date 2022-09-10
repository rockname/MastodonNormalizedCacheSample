import Foundation

protocol Request {
    associatedtype Response: Decodable
    var baseURL: URL { get }
    var method: HttpMethod { get }
    var path: String { get }
    var headerFields: [String: String] { get }
    var queryParameters: [String: String]? { get }
    var bodyParameters: BodyParameters? { get }
}

extension Request {
    var baseURL: URL { URL(string: "https://mstdn.jp/api/v1")! }

    var headerFields: [String: String] { [:] }

    var queryParameters: [String: String]? { nil }

    var bodyParameters: BodyParameters? { nil }
}

public enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
}

protocol BodyParameters {
    var contentType: String { get }
    func encode() throws -> Data
}

extension BodyParameters where Self: Encodable {
    var contentType: String {
        "application/json; charset=utf-8"
    }

    func encode() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }
}
