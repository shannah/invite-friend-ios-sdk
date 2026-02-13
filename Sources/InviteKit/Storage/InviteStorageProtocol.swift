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
