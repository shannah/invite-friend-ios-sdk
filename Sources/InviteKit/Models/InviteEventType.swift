import Foundation

/// Types of events that can be recorded for an invite.
public enum InviteEventType: String, Codable {
    /// The invite link was opened/accepted.
    case accepted

    /// The app was installed through the invite.
    case installed

    /// Attribution was recorded for the invite.
    case attributed
}
