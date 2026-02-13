import Foundation
import os.log

/// Internal logging utility for the CN1InviteKit SDK.
enum Logger {

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

    static var minimumLevel: Level = .warning
    static var isEnabled: Bool = true

    private static let subsystem = "com.cn1invite.CN1InviteKit"
    private static let osLog = OSLog(subsystem: subsystem, category: "CN1InviteKit")

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
        print("[CN1InviteKit] \(formattedMessage)")
        #endif

        os_log("%{public}@", log: osLog, type: level.osLogType, formattedMessage)
    }
}
