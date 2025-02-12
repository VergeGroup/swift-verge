//
//  Log.swift
//  VergeCore
//
//  Created by muukii on 2020/02/24.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import os.log

public enum VergeOSLogs {
  public static let debugLog = OSLog(subsystem: "Verge", category: "Debug")
}

enum Log {
  
  static func debug(
    file: StaticString = #file,
    line: UInt = #line,
    _ log: OSLog,
    _ object: @autoclosure () -> Any
  ) {
    os_log(.default, log: log, "%{public}@\n%{public}@:%{public}@", "\(object())", "\(file)", "\(line.description)")
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
  
  static let storeReader: OSLog = makeOSLogInDebug { OSLog.init(subsystem: "org.VergeGroup", category: "StoreReader") }
  
  static let writeGraph: OSLog = makeOSLogInDebug { OSLog.init(subsystem: "org.VergeGroup", category: "WriteGraph") }
}
