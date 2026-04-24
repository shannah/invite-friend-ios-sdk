import Foundation

/// Storage implementation using App Groups for sharing data between app and App Clip.
///
/// This storage uses `UserDefaults` with an App Group suite name to persist
/// invite data that can be accessed by both the main app and its App Clip.
///
/// ## Setup
/// To use App Group storage, you must:
/// 1. Enable App Groups capability in your app and App Clip targets
/// 2. Create an App Group with the identifier `group.{bundleId}.invite`
/// 3. Add the App Group to both targets' entitlements
public final class AppGroupStorage: InviteStorageProtocol {

    // MARK: - Storage Keys

    private enum Keys {
        static let referrerId = "invite.referrerId"
        static let shortCode = "invite.shortCode"
        static let metadata = "invite.metadata"
        static let createdAt = "invite.createdAt"
        static let version = "invite.version"
    }

    // MARK: - Properties

    private let userDefaults: UserDefaults
    private let dateFormatter: ISO8601DateFormatter

    /// The current storage version for migration support.
    private static let currentVersion = 1

    // MARK: - Initialization

    /// Creates a new App Group storage instance.
    ///
    /// - Parameter suiteName: The App Group suite name. If `nil`, attempts to
    ///   derive it from the bundle identifier.
    public init(suiteName: String? = nil) {
        let suite = suiteName ?? AppGroupStorage.defaultSuiteName()

        if let defaults = UserDefaults(suiteName: suite) {
            self.userDefaults = defaults
            Logger.log("AppGroupStorage initialized with suite: \(suite)", level: .debug)
        } else {
            Logger.log("Failed to create UserDefaults with suite '\(suite)', using standard", level: .warning)
            self.userDefaults = UserDefaults.standard
        }

        self.dateFormatter = ISO8601DateFormatter()
        self.dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }

    /// Creates a storage instance with a specific UserDefaults instance (for testing).
    internal init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        self.dateFormatter = ISO8601DateFormatter()
        self.dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }

    // MARK: - InviteStorageProtocol

    public func saveInvite(_ invite: InviteResult) {
        if let referrerId = invite.referrerId {
            userDefaults.set(referrerId, forKey: Keys.referrerId)
        } else {
            userDefaults.removeObject(forKey: Keys.referrerId)
        }
        userDefaults.set(invite.shortCode, forKey: Keys.shortCode)
        userDefaults.set(dateFormatter.string(from: invite.createdAt), forKey: Keys.createdAt)
        userDefaults.set(AppGroupStorage.currentVersion, forKey: Keys.version)

        if let metadata = invite.metadata {
            if let encoded = try? JSONEncoder().encode(metadata) {
                userDefaults.set(encoded, forKey: Keys.metadata)
            }
        } else {
            userDefaults.removeObject(forKey: Keys.metadata)
        }

        userDefaults.synchronize()
        Logger.log("Invite saved to App Group storage", level: .debug)
    }

    public func getInvite() -> InviteResult? {
        let referrerId = userDefaults.string(forKey: Keys.referrerId)
        guard let shortCode = userDefaults.string(forKey: Keys.shortCode),
              let createdAtString = userDefaults.string(forKey: Keys.createdAt),
              let createdAt = dateFormatter.date(from: createdAtString) else {
            return nil
        }

        var metadata: [String: String]?
        if let metadataData = userDefaults.data(forKey: Keys.metadata) {
            metadata = try? JSONDecoder().decode([String: String].self, from: metadataData)
        }

        return InviteResult(
            referrerId: referrerId,
            shortCode: shortCode,
            metadata: metadata,
            createdAt: createdAt
        )
    }

    public func clearInvite() {
        userDefaults.removeObject(forKey: Keys.referrerId)
        userDefaults.removeObject(forKey: Keys.shortCode)
        userDefaults.removeObject(forKey: Keys.metadata)
        userDefaults.removeObject(forKey: Keys.createdAt)
        userDefaults.removeObject(forKey: Keys.version)
        userDefaults.synchronize()

        Logger.log("Invite data cleared from App Group storage", level: .debug)
    }

    public func hasInvite() -> Bool {
        return userDefaults.string(forKey: Keys.shortCode) != nil
    }

    // MARK: - Private Helpers

    private static func defaultSuiteName() -> String {
        let bundleId = Bundle.main.bundleIdentifier ?? "com.unknown"
        // Remove App Clip suffix if present to get base bundle ID
        let baseBundleId = bundleId.replacingOccurrences(of: ".Clip", with: "")
        return "group.\(baseBundleId).invite"
    }
}
