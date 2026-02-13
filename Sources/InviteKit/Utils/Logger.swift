import Foundation
import os.log

/// Internal logging utility for the InviteKit SDK.
enum Logger {

    /// Log levels for filtering output.
    enum Level: Int, Comparable {
        case debug = 0
        case info = 1
        case warning = 2
        case error = 3

        static func < (lhs: Level, rhs: Level) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        var prefix: String {
            switch self {
            case .debug: return "DEBUG"
            case .info: return "INFO"
            case .warning: return "WARNING"
            case .error: return "ERROR"
            }
        }

        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            }
        }
    }

    // MARK: - Properties

    /// The minimum log level. Messages below this level are ignored.
    static var minimumLevel: Level = .warning

    /// Whether logging is enabled.
    static var isEnabled: Bool = true

    private static let subsystem = "com.cn1invite.InviteKit"
    private static let osLog = OSLog(subsystem: subsystem, category: "InviteKit")

    // MARK: - Logging

    /// Logs a message at the specified level.
    ///
    /// - Parameters:
    ///   - message: The message to log.
    ///   - level: The log level.
    ///   - file: The file where the log was called.
    ///   - function: The function where the log was called.
    ///   - line: The line number where the log was called.
    static func log(
        _ message: String,
        level: Level,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard isEnabled, level >= minimumLevel else { return }

        let fileName = (file as NSString).lastPathComponent
        let formattedMessage = "[\(level.prefix)] [\(fileName):\(line)] \(function): \(message)"

        #if DEBUG
        print("[InviteKit] \(formattedMessage)")
        #endif

        os_log("%{public}@", log: osLog, type: level.osLogType, formattedMessage)
    }
}
