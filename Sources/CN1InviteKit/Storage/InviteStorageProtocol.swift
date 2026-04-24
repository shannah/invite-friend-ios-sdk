import Foundation

/// Protocol defining storage operations for invite data.
///
/// This abstraction allows for different storage implementations
/// and enables easy testing with mock objects.
public protocol InviteStorageProtocol {

    /// Saves an invite result to storage.
    ///
    /// - Parameter invite: The invite result to save.
    func saveInvite(_ invite: InviteResult)

    /// Retrieves the stored invite result.
    ///
    /// - Returns: The stored invite result, or `nil` if none exists.
    func getInvite() -> InviteResult?

    /// Clears any stored invite data.
    func clearInvite()

    /// Checks if invite data exists in storage.
    ///
    /// - Returns: `true` if invite data exists, `false` otherwise.
    func hasInvite() -> Bool
}

/// Represents the result of creating an invite link or checking attribution.
/// Duplicated here to avoid dependency on InviteKit module.
public struct InviteResult: Codable, Equatable {

    /// The unique identifier of the user who created the invite.
    /// May be `nil` when the invite URL did not include a `ref` query parameter.
    public let referrerId: String?

    /// The short code for the invite link.
    public let shortCode: String

    /// Optional metadata associated with the invite.
    public let metadata: [String: String]?

    /// The date when the invite was created.
    public let createdAt: Date

    /// Creates a new invite result.
    public init(
        referrerId: String?,
        shortCode: String,
        metadata: [String: String]? = nil,
        createdAt: Date = Date()
    ) {
        self.referrerId = referrerId
        self.shortCode = shortCode
        self.metadata = metadata
        self.createdAt = createdAt
    }
}
