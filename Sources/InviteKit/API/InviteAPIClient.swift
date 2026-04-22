import Foundation

/// Default implementation of `InviteAPIClientProtocol` using URLSession.
public final class InviteAPIClient: InviteAPIClientProtocol {

    // MARK: - Properties

    private let apiKey: String
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // MARK: - Initialization

    /// Creates a new API client.
    ///
    /// - Parameters:
    ///   - apiKey: The API key for authentication.
    ///   - baseURL: The base URL for API requests.
    ///   - session: The URL session to use. Defaults to `.shared`.
    public init(apiKey: String, baseURL: URL, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.session = session

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - InviteAPIClientProtocol

    public func createInvite(referrerId: String, metadata: [String: String]?) async throws -> InviteResult {
        let endpoint = baseURL.appendingPathComponent("/api/v1/sdk/invites")

        var request = makeRequest(url: endpoint, method: "POST")

        let body = CreateInviteRequest(referrerId: referrerId, metadata: metadata)
        request.httpBody = try encoder.encode(body)

        let response: CreateInviteResponse = try await performRequest(request)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let createdAt = formatter.date(from: response.createdAt)
            ?? ISO8601DateFormatter().date(from: response.createdAt)
            ?? Date()

        return InviteResult(
            referrerId: referrerId,
            shortCode: response.shortCode,
            metadata: metadata,
            createdAt: createdAt
        )
    }

    public func getInvite(shortCode: String) async throws -> InviteResult {
        let endpoint = baseURL.appendingPathComponent("/api/v1/sdk/invites/\(shortCode)")

        let request = makeRequest(url: endpoint, method: "GET")
        let response: InviteDetailsResponse = try await performRequest(request)

        return InviteResult(
            referrerId: response.referrerId,
            shortCode: response.shortCode,
            metadata: response.metadata,
            createdAt: response.createdAt
        )
    }

    public func recordEvent(shortCode: String, eventType: InviteEventType) async throws {
        let endpoint = baseURL.appendingPathComponent("/api/v1/sdk/invites/\(shortCode)/events")

        var request = makeRequest(url: endpoint, method: "POST")

        let body = RecordEventRequest(eventType: eventType)
        request.httpBody = try encoder.encode(body)

        let _: EmptyResponse = try await performRequest(request)
    }

    public func getConfig() async throws -> InviteConfig {
        let endpoint = baseURL.appendingPathComponent("/api/v1/sdk/config")

        let request = makeRequest(url: endpoint, method: "GET")
        let response: ConfigResponse = try await performRequest(request)

        return InviteConfig(
            projectId: response.projectId,
            projectSlug: response.projectSlug,
            appName: response.appName,
            isActive: response.isActive
        )
    }

    public func ping() async -> Bool {
        let endpoint = baseURL.appendingPathComponent("/api/v1/sdk/ping")
        let request = makeRequest(url: endpoint, method: "GET")

        do {
            let (_, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            return httpResponse.statusCode == 200
        } catch {
            Logger.log("Ping failed: \(error)", level: .debug)
            return false
        }
    }

    // MARK: - Private Helpers

    private func makeRequest(url: URL, method: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("InviteKit/1.0.0", forHTTPHeaderField: "User-Agent")
        return request
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw InviteError.networkError(URLError(.badServerResponse))
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                Logger.log("Decode error: \(error)", level: .error)
                throw InviteError.unknown("Failed to decode response")
            }

        case 401:
            throw InviteError.invalidAPIKey

        case 404:
            throw InviteError.inviteNotFound

        case 429:
            throw InviteError.rateLimited

        default:
            let message = try? decoder.decode(ErrorResponse.self, from: data).message
            throw InviteError.serverError(statusCode: httpResponse.statusCode, message: message)
        }
    }
}

// MARK: - Request/Response Models

struct CreateInviteRequest: Encodable {
    let referrerId: String
    let metadata: [String: String]?
}

struct CreateInviteResponse: Decodable {
    let inviteUrl: String
    let shortCode: String
    let createdAt: String
    let warning: String?
}

struct InviteDetailsResponse: Decodable {
    let shortCode: String
    let referrerId: String
    let metadata: [String: String]?
    let createdAt: Date
}

struct RecordEventRequest: Encodable {
    let eventType: InviteEventType
}

struct ConfigResponse: Decodable {
    let projectId: String
    let projectSlug: String
    let appName: String
    let isActive: Bool
}

struct ErrorResponse: Decodable {
    let message: String
}

struct EmptyResponse: Decodable {}
