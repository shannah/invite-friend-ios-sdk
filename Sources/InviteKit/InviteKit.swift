import Foundation

/// InviteKit is the main SDK for creating and managing invite links in your iOS application.
///
/// ## Overview
/// InviteKit provides functionality for:
/// - Creating shareable invite links with referrer attribution
/// - Checking for invite attribution from App Clips
/// - Recording invite-related events
///
/// ## Getting Started
/// Configure the SDK with your API key before using any other methods:
/// ```swift
/// InviteKit.configure(apiKey: "your-api-key")
/// ```
///
/// ## Creating Invite Links
/// ```swift
/// let result = try await InviteKit.createInviteLink(referrerId: "user123")
/// print("Share this link: \(result.inviteURL)")
/// ```
///
/// ## Checking Attribution
/// ```swift
/// if let invite = InviteKit.checkForInvite() {
///     print("Referred by: \(invite.referrerId)")
/// }
/// ```
public final class InviteKit {

    // MARK: - Shared Instance

    /// The shared InviteKit instance.
    static let shared = InviteKit()

    // MARK: - Properties

    private var apiKey: String?
    private var baseURL: URL?
    private var apiClient: InviteAPIClientProtocol?
    private var storage: InviteStorageProtocol?
    private var isConfigured = false

    // MARK: - Initialization

    private init() {}

    // MARK: - Configuration

    /// Configures the SDK with your API key using the default base URL.
    ///
    /// - Parameter apiKey: Your InviteKit API key.
    /// - Important: This method must be called before using any other SDK methods.
    public static func configure(apiKey: String) {
        configure(apiKey: apiKey, baseURL: URL(string: "https://api.cn1invite.com")!)
    }

    /// Configures the SDK with your API key and a custom base URL.
    ///
    /// - Parameters:
    ///   - apiKey: Your InviteKit API key.
    ///   - baseURL: The base URL for API requests.
    /// - Important: This method must be called before using any other SDK methods.
    public static func configure(apiKey: String, baseURL: URL) {
        shared.apiKey = apiKey
        shared.baseURL = baseURL
        shared.apiClient = InviteAPIClient(apiKey: apiKey, baseURL: baseURL)
        shared.storage = AppGroupStorage()
        shared.isConfigured = true

        Logger.log("InviteKit configured with base URL: \(baseURL)", level: .info)
    }

    // MARK: - Invite Link Creation

    /// Creates a new invite link for the specified referrer.
    ///
    /// - Parameters:
    ///   - referrerId: The unique identifier for the user creating the invite.
    ///   - metadata: Optional dictionary of additional metadata to associate with the invite.
    /// - Returns: An `InviteResult` containing the created invite details.
    /// - Throws: `InviteError` if the operation fails.
    public static func createInviteLink(
        referrerId: String,
        metadata: [String: String]? = nil
    ) async throws -> InviteResult {
        try ensureConfigured()

        guard let apiClient = shared.apiClient else {
            throw InviteError.notConfigured
        }

        return try await apiClient.createInvite(referrerId: referrerId, metadata: metadata)
    }

    /// Creates a new invite link for the specified referrer using a completion handler.
    ///
    /// - Parameters:
    ///   - referrerId: The unique identifier for the user creating the invite.
    ///   - metadata: Optional dictionary of additional metadata to associate with the invite.
    ///   - completion: A closure called with the result of the operation.
    public static func createInviteLink(
        referrerId: String,
        metadata: [String: String]? = nil,
        completion: @escaping (Result<InviteResult, InviteError>) -> Void
    ) {
        Task {
            do {
                let result = try await createInviteLink(referrerId: referrerId, metadata: metadata)
                completion(.success(result))
            } catch let error as InviteError {
                completion(.failure(error))
            } catch {
                completion(.failure(.networkError(error)))
            }
        }
    }

    // MARK: - Invite Lookup

    /// Retrieves invite details from the server by short code.
    ///
    /// Use this to look up the full invite details (including referrerId) when the
    /// locally stored invite may not have all fields (e.g. URL had no `ref` parameter).
    ///
    /// - Parameter shortCode: The short code of the invite to look up.
    /// - Returns: An `InviteResult` containing the full invite details.
    /// - Throws: `InviteError` if the operation fails.
    public static func getInvite(shortCode: String) async throws -> InviteResult {
        try ensureConfigured()

        guard let apiClient = shared.apiClient else {
            throw InviteError.notConfigured
        }

        return try await apiClient.getInvite(shortCode: shortCode)
    }

    // MARK: - Attribution Checking

    /// Checks for any pending invite attribution from an App Clip.
    ///
    /// - Returns: An `InviteResult` if attribution data exists, or `nil` if none is found.
    public static func checkForInvite() -> InviteResult? {
        guard let storage = shared.storage else {
            Logger.log("Storage not configured", level: .warning)
            return nil
        }

        return storage.getInvite()
    }

    /// Clears any stored invite attribution data.
    public static func clearInvite() {
        shared.storage?.clearInvite()
        Logger.log("Invite data cleared", level: .info)
    }

    // MARK: - Event Recording

    /// Records an event for the specified invite.
    ///
    /// - Parameters:
    ///   - shortCode: The short code of the invite.
    ///   - eventType: The type of event to record.
    /// - Throws: `InviteError` if the operation fails.
    public static func recordEvent(shortCode: String, eventType: InviteEventType) async throws {
        try ensureConfigured()

        guard let apiClient = shared.apiClient else {
            throw InviteError.notConfigured
        }

        try await apiClient.recordEvent(shortCode: shortCode, eventType: eventType)
        Logger.log("Event recorded: \(eventType) for \(shortCode)", level: .info)
    }

    /// Records an event for the specified invite using a completion handler.
    ///
    /// - Parameters:
    ///   - shortCode: The short code of the invite.
    ///   - eventType: The type of event to record.
    ///   - completion: A closure called with the result of the operation.
    public static func recordEvent(
        shortCode: String,
        eventType: InviteEventType,
        completion: @escaping (Result<Void, InviteError>) -> Void
    ) {
        Task {
            do {
                try await recordEvent(shortCode: shortCode, eventType: eventType)
                completion(.success(()))
            } catch let error as InviteError {
                completion(.failure(error))
            } catch {
                completion(.failure(.networkError(error)))
            }
        }
    }

    // MARK: - Observer Pattern

    /// Registers an observer for invite attribution changes.
    ///
    /// - Parameter observer: A closure called when invite attribution is detected.
    /// - Returns: An `ObservationToken` that can be used to unregister the observer.
    @discardableResult
    public static func registerInviteObserver(_ observer: @escaping (InviteResult) -> Void) -> ObservationToken {
        // TODO: Implement observer pattern
        return ObservationToken {}
    }

    // MARK: - Internal Configuration

    /// Configures the SDK with custom dependencies for testing.
    internal static func configure(
        apiKey: String,
        apiClient: InviteAPIClientProtocol,
        storage: InviteStorageProtocol
    ) {
        shared.apiKey = apiKey
        shared.apiClient = apiClient
        shared.storage = storage
        shared.isConfigured = true
    }

    /// Resets the SDK configuration. Used for testing.
    internal static func reset() {
        shared.apiKey = nil
        shared.baseURL = nil
        shared.apiClient = nil
        shared.storage = nil
        shared.isConfigured = false
    }

    // MARK: - Private Helpers

    private static func ensureConfigured() throws {
        guard shared.isConfigured else {
            throw InviteError.notConfigured
        }
    }
}

// MARK: - Observation Token

/// A token that represents an active observation.
/// Call `cancel()` or let it deinitialize to stop receiving updates.
public final class ObservationToken {
    private let cancellation: () -> Void

    init(_ cancellation: @escaping () -> Void) {
        self.cancellation = cancellation
    }

    deinit {
        cancel()
    }

    /// Cancels the observation.
    public func cancel() {
        cancellation()
    }
}
