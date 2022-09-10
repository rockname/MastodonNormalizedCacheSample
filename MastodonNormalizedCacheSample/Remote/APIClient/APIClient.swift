import Foundation
import Combine

enum APIError: Error {
    case noResponse
    case unacceptableStatusCode(Int)
    case failedToCreateComponents(URL)
    case failedToCreateURL(URLComponents)
}

class APIClient {
    private let accessToken: () -> String?
    private let session: URLSession

    // ref: https://github.com/mastodon/mastodon-ios/blob/6153839157c880bf116744f29abeed443d76e614/MastodonSDK/Sources/MastodonSDK/API/Mastodon%2BAPI.swift#L37
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.custom { decoder throws -> Date in
            let container = try decoder.singleValueContainer()

            var logInfo = ""
            do {
                let string = try container.decode(String.self)
                logInfo += string

                let fractionalSecondsPreciseISO8601Formatter = ISO8601DateFormatter()
                fractionalSecondsPreciseISO8601Formatter.formatOptions.insert(.withFractionalSeconds)
                if let date = fractionalSecondsPreciseISO8601Formatter.date(from: string) {
                    return date
                }

                let fullDatePreciseISO8601Formatter = ISO8601DateFormatter()
                fullDatePreciseISO8601Formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
                if let date = fullDatePreciseISO8601Formatter.date(from: string) {
                    return date
                }

                if let timestamp = TimeInterval(string) {
                    return Date(timeIntervalSince1970: timestamp)
                }
            } catch {
                // do nothing
            }

            do {
                let number = try container.decode(Double.self)
                logInfo += "\(number)"

                return Date(timeIntervalSince1970: number)
            } catch {
                // do nothing
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "[Decoder] Invalid date: \(logInfo)")
        }
        return decoder
    }()

    init(
        accessToken: @escaping () -> String? = { try? AuthenticationStore.shared.load()?.accessToken },
        session: URLSession = .shared
    ) {
        self.accessToken = accessToken
        self.session = session
    }

    func send<T: Request>(_ request: T) async throws -> T.Response {
        let url = request.baseURL.appendingPathComponent(request.path)

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            throw APIError.failedToCreateComponents(url)
        }

        components.queryItems = request.queryParameters?.compactMap(URLQueryItem.init)

        guard var urlRequest = components.url.map({ URLRequest(url: $0) }) else {
            throw APIError.failedToCreateURL(components)
        }

        urlRequest.httpMethod = request.method.rawValue

        if let bodyParameters = request.bodyParameters {
            urlRequest.setValue(bodyParameters.contentType, forHTTPHeaderField: "Content-Type")
            do {
                let body = try bodyParameters.encode()
                urlRequest.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
                urlRequest.httpBody = body
            } catch {
                throw error
            }
        }

        if let token = accessToken() {
            let authorization = ["Authorization": "Bearer \(token)"]
            urlRequest.allHTTPHeaderFields = request.headerFields.merging(authorization, uniquingKeysWith: +)
        } else {
            urlRequest.allHTTPHeaderFields = request.headerFields
        }

        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let response = response as? HTTPURLResponse else {
                throw APIError.noResponse
            }

            guard  200..<300 ~= response.statusCode else {
                if let error = try? decoder.decode(MastodonError.self, from: data) {
                    throw error
                } else {
                    throw APIError.unacceptableStatusCode(response.statusCode)
                }
            }

            do {
                return try decoder.decode(T.Response.self, from: data)
            } catch {
                throw error
            }
        } catch {
            throw error
        }
    }
}
