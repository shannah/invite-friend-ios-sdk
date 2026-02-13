import Foundation

/// Represents the result of creating an invite link or checking attribution.
public struct InviteResult: Codable, Equatable {

    /// The unique identifier of the user who created the invite.
    public let referrerId: String

    /// The short code for the invite link.
    public let shortCode: String

    /// Optional metadata associated with the invite.
    public let metadata: [String: String]?

    /// The date when the invite was created.
    public let createdAt: Date

    /// The full invite URL.
    public var inviteURL: URL? {
        URL(string: "https://cn1invite.com/i/\(shortCode)?ref=\(referrerId)")
    }

    /// Creates a new invite result.
    ///
    /// - Parameters:
    ///   - referrerId: The unique identifier of the referrer.
    ///   - shortCode: The short code for the invite link.
    ///   - metadata: Optional metadata dictionary.
    ///   - createdAt: The creation date.
    public init(
        referrerId: String,
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
