import Foundation

/// Protocol defining the API client interface for invite operations.
///
/// This abstraction enables testing with mock implementations and
/// allows for alternative API client implementations.
public protocol InviteAPIClientProtocol {

    /// Creates a new invite link.
    ///
    /// - Parameters:
    ///   - referrerId: The unique identifier of the referrer.
    ///   - metadata: Optional metadata to associate with the invite.
    /// - Returns: An `InviteResult` containing the created invite details.
    /// - Throws: `InviteError` if the operation fails.
    func createInvite(referrerId: String, metadata: [String: String]?) async throws -> InviteResult

    /// Retrieves details for an existing invite.
    ///
    /// - Parameter shortCode: The short code of the invite.
    /// - Returns: An `InviteResult` containing the invite details.
    /// - Throws: `InviteError` if the operation fails.
    func getInvite(shortCode: String) async throws -> InviteResult

    /// Records an event for an invite.
    ///
    /// - Parameters:
    ///   - shortCode: The short code of the invite.
    ///   - eventType: The type of event to record.
    /// - Throws: `InviteError` if the operation fails.
    func recordEvent(shortCode: String, eventType: InviteEventType) async throws

    /// Fetches the configuration for the current API key.
    ///
    /// - Returns: An `InviteConfig` containing the project configuration.
    /// - Throws: `InviteError` if the operation fails.
    func getConfig() async throws -> InviteConfig

    /// Performs a health check on the API.
    ///
    /// - Returns: `true` if the API is healthy, `false` otherwise.
    func ping() async -> Bool
}
