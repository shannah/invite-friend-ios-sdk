import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(StoreKit)
import StoreKit
#endif

/// CN1InviteKit is a lightweight SDK for handling invite links in App Clips.
///
/// ## Overview
/// CN1InviteKit provides functionality for:
/// - Parsing invite URLs to extract referrer information
/// - Storing invite data in App Groups for the main app to access
/// - Presenting the full app download overlay via StoreKit
///
/// ## App Clip Usage
/// Handle invite URLs in your App Clip's `onContinueUserActivity`:
/// ```swift
/// .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
///     if let url = activity.webpageURL {
///         CN1InviteKit.handleInvite(url: url, in: scene)
///     }
/// }
/// ```
///
/// ## URL Format
/// Invite URLs follow this format:
/// ```
/// https://{project-slug}.cn1invite.com/i/{shortCode}?ref={referrerId}&meta={metadata}
/// ```
public final class CN1InviteKit {

    // MARK: - Shared Instance

    /// The shared CN1InviteKit instance.
    static let shared = CN1InviteKit()

    // MARK: - Properties

    private var storage: InviteStorageProtocol?
    private var appStoreId: String?

    // MARK: - Initialization

    private init() {
        self.storage = AppGroupStorage()
    }

    // MARK: - Configuration

    /// Configures the App Clip SDK with the App Store ID for overlay presentation.
    ///
    /// - Parameter appStoreId: Your app's App Store ID for the download overlay.
    public static func configure(appStoreId: String) {
        shared.appStoreId = appStoreId
        Logger.log("CN1InviteKit configured with App Store ID: \(appStoreId)", level: .info)
    }

    // MARK: - URL Parsing

    /// Parses an invite URL and extracts the invite data.
    ///
    /// - Parameter url: The invite URL to parse.
    /// - Returns: An `InviteData` object if the URL is valid, or `nil` if parsing fails.
    ///
    /// ## URL Format
    /// ```
    /// https://{project-slug}.cn1invite.com/i/{shortCode}?ref={referrerId}&meta={metadata}
    /// ```
    public static func parseInviteURL(_ url: URL) -> InviteData? {
        Logger.log("Parsing invite URL: \(url)", level: .debug)

        // Validate host contains cn1invite.com
        guard let host = url.host, host.contains("cn1invite.com") else {
            Logger.log("Invalid host: \(url.host ?? "nil")", level: .warning)
            return nil
        }

        // Extract path components: /i/{shortCode}
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        guard pathComponents.count >= 2,
              pathComponents[0] == "i" else {
            Logger.log("Invalid path format", level: .warning)
            return nil
        }

        let shortCode = pathComponents[1]

        // Parse query parameters
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            Logger.log("Failed to parse URL components", level: .warning)
            return nil
        }

        let queryItems = components.queryItems ?? []
        let referrerId = queryItems.first(where: { $0.name == "ref" })?.value

        guard let referrerId = referrerId else {
            Logger.log("Missing required 'ref' parameter", level: .warning)
            return nil
        }

        // Parse optional metadata (base64 encoded JSON)
        var metadata: [String: String]?
        if let metaString = queryItems.first(where: { $0.name == "meta" })?.value,
           let metaData = Data(base64Encoded: metaString),
           let decoded = try? JSONDecoder().decode([String: String].self, from: metaData) {
            metadata = decoded
        }

        let inviteData = InviteData(
            referrerId: referrerId,
            shortCode: shortCode,
            metadata: metadata,
            createdAt: Date()
        )

        Logger.log("Successfully parsed invite: referrerId=\(referrerId), shortCode=\(shortCode)", level: .info)
        return inviteData
    }

    // MARK: - Storage

    /// Stores invite data in App Group storage for the main app to access.
    ///
    /// - Parameter invite: The invite data to store.
    /// - Returns: `true` if storage succeeded, `false` otherwise.
    @discardableResult
    public static func storeInvite(_ invite: InviteData) -> Bool {
        guard let storage = shared.storage else {
            Logger.log("Storage not available", level: .error)
            return false
        }

        let result = InviteResult(
            referrerId: invite.referrerId,
            shortCode: invite.shortCode,
            metadata: invite.metadata,
            createdAt: invite.createdAt
        )

        storage.saveInvite(result)
        Logger.log("Invite stored successfully", level: .info)
        return true
    }

    /// Retrieves stored invite data.
    ///
    /// - Returns: The stored `InviteData` if available, or `nil` if none exists.
    public static func getStoredInvite() -> InviteData? {
        guard let storage = shared.storage,
              let result = storage.getInvite() else {
            return nil
        }

        return InviteData(
            referrerId: result.referrerId,
            shortCode: result.shortCode,
            metadata: result.metadata,
            createdAt: result.createdAt
        )
    }

    // MARK: - StoreKit Overlay

    #if canImport(UIKit) && canImport(StoreKit)
    /// Presents the full app download overlay using StoreKit.
    ///
    /// - Parameter windowScene: The window scene to present the overlay in.
    @available(iOS 14.0, *)
    public static func presentFullAppOverlay(in windowScene: UIWindowScene) {
        guard let appStoreId = shared.appStoreId else {
            Logger.log("App Store ID not configured. Call configure(appStoreId:) first.", level: .error)
            return
        }

        let config = SKOverlay.AppClipConfiguration(position: .bottom)
        let overlay = SKOverlay(configuration: config)

        overlay.present(in: windowScene)
        Logger.log("Presenting full app overlay", level: .info)
    }

    /// Dismisses the full app download overlay.
    ///
    /// - Parameter windowScene: The window scene containing the overlay.
    @available(iOS 14.0, *)
    public static func dismissFullAppOverlay(in windowScene: UIWindowScene) {
        SKOverlay.dismiss(in: windowScene)
        Logger.log("Dismissed full app overlay", level: .info)
    }
    #endif

    // MARK: - Convenience Methods

    #if canImport(UIKit) && canImport(StoreKit)
    /// Handles an invite URL by parsing, storing, and presenting the full app overlay.
    ///
    /// This is a convenience method that combines `parseInviteURL`, `storeInvite`,
    /// and `presentFullAppOverlay` into a single call.
    ///
    /// - Parameters:
    ///   - url: The invite URL to handle.
    ///   - windowScene: The window scene for overlay presentation.
    /// - Returns: The parsed `InviteData` if successful, or `nil` if parsing failed.
    @available(iOS 14.0, *)
    @discardableResult
    public static func handleInvite(url: URL, in windowScene: UIWindowScene) -> InviteData? {
        guard let inviteData = parseInviteURL(url) else {
            Logger.log("Failed to parse invite URL", level: .warning)
            return nil
        }

        storeInvite(inviteData)
        presentFullAppOverlay(in: windowScene)

        return inviteData
    }
    #endif

    // MARK: - Internal Configuration

    /// Configures the SDK with a custom storage implementation for testing.
    internal static func configure(storage: InviteStorageProtocol) {
        shared.storage = storage
    }

    /// Resets the SDK configuration. Used for testing.
    internal static func reset() {
        shared.storage = AppGroupStorage()
        shared.appStoreId = nil
    }
}
