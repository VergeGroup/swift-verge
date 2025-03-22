//
//  Log.swift
//  VergeCore
//
//  Created by muukii on 2020/02/24.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import os.log

enum Log {
    
  static let store = Logger(OSLog.makeOSLogInDebug { OSLog.init(subsystem: "Verge", category: "store") })
  
  static let storeCommit = Logger(OSLog.makeOSLogInDebug { OSLog.init(subsystem: "Verge", category: "store.commit") })
  
  static let storeReader = Logger(OSLog.makeOSLogInDebug { OSLog.init(subsystem: "Verge", category: "storeReader") })
  
  static let reading = Logger(OSLog.makeOSLogInDebug { OSLog.init(subsystem: "Verge", category: "reading") })
  
  static let writeGraph = Logger(OSLog.makeOSLogInDebug { OSLog.init(subsystem: "Verge", category: "writeGraph") })
  
}

extension OSLog {
  
  @inline(__always)
  fileprivate static func makeOSLogInDebug(isEnabled: Bool = true, _ factory: () -> OSLog) -> OSLog {
#if DEBUG
    return factory()
#else
    return .disabled
#endif
  }
  
}
