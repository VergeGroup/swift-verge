import UIKit
import os.log

enum Log {

  static func debug(_ log: OSLog, _ object: Any...) {
    if #available(iOS 12.0, *) {
      os_log(.debug, log: log, "%@", object.map { "\($0)" }.joined(separator: " "))
    }
  }

  static func error(_ log: OSLog, _ object: Any...) {
    if #available(iOS 12.0, *) {
      os_log(.error, log: log, "%@", object.map { "\($0)" }.joined(separator: " "))
    }
  }

}

extension OSLog {

  private static let isDebugEnabled: Bool = {
    true
  }()

  private static func makeLogger(category: String) -> OSLog {
#if DEBUG
    if isDebugEnabled {
      return OSLog.init(subsystem: "AsyncVerge", category: category)
    } else {
      return .disabled
    }
#else
    return .disabled
#endif
  }

  static let storage: OSLog = {
    return makeLogger(category: "📦 Storage")
  }()

}
