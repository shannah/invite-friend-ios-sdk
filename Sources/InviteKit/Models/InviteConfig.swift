import Foundation

/// Configuration data retrieved from the server.
public struct InviteConfig: Codable, Equatable {

    /// The project identifier.
    public let projectId: String

    /// The project slug used in URLs.
    public let projectSlug: String

    /// The display name of the app.
    public let appName: String

    /// Whether the project is active.
    public let isActive: Bool

    /// Creates a new invite configuration.
    ///
    /// - Parameters:
    ///   - projectId: The project identifier.
    ///   - projectSlug: The project slug for URLs.
    ///   - appName: The display name of the app.
    ///   - isActive: Whether the project is active.
    public init(
        projectId: String,
        projectSlug: String,
        appName: String,
        isActive: Bool = true
    ) {
        self.projectId = projectId
        self.projectSlug = projectSlug
        self.appName = appName
        self.isActive = isActive
    }
}
