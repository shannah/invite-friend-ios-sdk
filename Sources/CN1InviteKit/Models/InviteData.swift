import Foundation

/// Represents invite data parsed from an App Clip URL.
public struct InviteData: Codable, Equatable {

    /// The unique identifier of the user who created the invite.
    /// May be `nil` when the invite URL does not include a `ref` query parameter;
    /// the main app can look up the referrer by short code from the server.
    public let referrerId: String?

    /// The short code for the invite link.
    public let shortCode: String

    /// Optional metadata associated with the invite.
    public let metadata: [String: String]?

    /// The date when the invite was received/parsed.
    public let createdAt: Date

    /// Creates a new invite data instance.
    ///
    /// - Parameters:
    ///   - referrerId: The unique identifier of the referrer (may be nil).
    ///   - shortCode: The short code for the invite link.
    ///   - metadata: Optional metadata dictionary.
    ///   - createdAt: The date when the invite was created/received.
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
