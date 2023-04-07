import os.log

enum Log {
  
  static func debug(
    file: StaticString = #file,
    line: UInt = #line,
    _ log: OSLog,
    _ object: @autoclosure () -> Any
  ) {
    os_log(.default, log: log, "%{public}@", "\(object())")
  }
  
  static func error(
    file: StaticString = #file,
    line: UInt = #line,
    _ log: OSLog,
    _ object: @autoclosure () -> Any
  ) {
    os_log(.error, log: log, "%{public}@\n%{public}@:%{public}@", "\(object())", "\(file)", "\(line.description)")
  }
  
}

extension OSLog {
  
  @inline(__always)
  private static func makeOSLogInDebug(isEnabled: Bool = true, _ factory: () -> OSLog) -> OSLog {
#if DEBUG
    return factory()
#else
    return .disabled
#endif
  }
  
  static let generic: OSLog = makeOSLogInDebug { OSLog.init(subsystem: "org.vergegroup.taskmanager", category: "generic") }
  static let taskManager: OSLog = makeOSLogInDebug { OSLog.init(subsystem: "org.vergegroup.taskmanager", category: "TaskManager") }
  static let taskQueue: OSLog = makeOSLogInDebug { OSLog.init(subsystem: "org.vergegroup.taskmanager", category: "TaskQueue") }
  static let taskNode: OSLog = makeOSLogInDebug { OSLog.init(subsystem: "org.vergegroup.taskmanager", category: "TaskNode") }
}
