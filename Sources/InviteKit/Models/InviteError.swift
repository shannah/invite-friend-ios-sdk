import Foundation

/// Errors that can occur when using the InviteKit SDK.
public enum InviteError: Error, Equatable {

    /// The SDK has not been configured. Call `InviteKit.configure(apiKey:)` first.
    case notConfigured

    /// The provided API key is invalid.
    case invalidAPIKey

    /// A network error occurred.
    case networkError(Error)

    /// The request was rate limited. Try again later.
    case rateLimited

    /// The server returned an error.
    case serverError(statusCode: Int, message: String?)

    /// The invite was not found.
    case inviteNotFound

    /// The request contained invalid parameters.
    case invalidParameters(String)

    /// An unknown error occurred.
    case unknown(String)

    // MARK: - Equatable

    public static func == (lhs: InviteError, rhs: InviteError) -> Bool {
        switch (lhs, rhs) {
        case (.notConfigured, .notConfigured):
            return true
        case (.invalidAPIKey, .invalidAPIKey):
            return true
        case (.networkError, .networkError):
            return true
        case (.rateLimited, .rateLimited):
            return true
        case let (.serverError(lCode, lMsg), .serverError(rCode, rMsg)):
            return lCode == rCode && lMsg == rMsg
        case (.inviteNotFound, .inviteNotFound):
            return true
        case let (.invalidParameters(lMsg), .invalidParameters(rMsg)):
            return lMsg == rMsg
        case let (.unknown(lMsg), .unknown(rMsg)):
            return lMsg == rMsg
        default:
            return false
        }
    }
}

// MARK: - LocalizedError

extension InviteError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "InviteKit has not been configured. Call InviteKit.configure(apiKey:) first."
        case .invalidAPIKey:
            return "The provided API key is invalid."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .rateLimited:
            return "Request rate limited. Please try again later."
        case .serverError(let statusCode, let message):
            if let message = message {
                return "Server error (\(statusCode)): \(message)"
            }
            return "Server error with status code \(statusCode)"
        case .inviteNotFound:
            return "The requested invite was not found."
        case .invalidParameters(let message):
            return "Invalid parameters: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}
