//
//  DefaultLogger.swift
//  VergeStore
//
//  Created by muukii on 2019/11/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import os

/// An object default implementation of VergeStoreLogger.
/// It uses `os_log` to print inside.
/// There are OSLog object each type of action.
/// You can turn off logging each OSLog object.
public final class DefaultLogger: VergeStoreLogger {
  
  public static let shared = DefaultLogger()
  
  public let commitLog = OSLog(subsystem: "VergeStore", category: "Commit")
  public let dispatchLog = OSLog(subsystem: "VergeStore", category: "Dispatch")
  public let dispatcherCreationLog = OSLog(subsystem: "VergeStore", category: "Dispatcher_Creation")
  public let dispatcherDestructionLog = OSLog(subsystem: "VergeStore", category: "Dispatcher_Descruction")
  
  let queue = DispatchQueue(label: "logger")
  
  public init() {
    
  }
  
  public func willCommit(store: AnyObject, state: Any, mutation: MutationMetadata, context: AnyObject?) {
  }
  
  public func didCommit(store: AnyObject, state: Any, mutation: MutationMetadata, context: AnyObject?, time: CFTimeInterval) {
    queue.async {
      os_log("%@", log: self.commitLog, type: .default, """
        {
          "type" : "commit",
          "took": "\(time * 1000)ms"
          "mutation" : \(mutation),
          "store" : "\(store)"
        }
        """
      )
    }
  }
  
  public func didDispatch(store: AnyObject, state: Any, action: ActionMetadata, context: AnyObject?) {
    queue.async {
      os_log("%@", log: self.dispatchLog, type: .default, """
        {
          "type" : "dispatch",
          "action" : \(action),
          "context" : \(context as Any),
          "store" : "\(store)"
        }
        """
      )
    }
  }
  
  public func didCreateDispatcher(store: AnyObject, dispatcher: Any) {
    queue.async {
      os_log("%@", log: self.dispatcherCreationLog, type: .default, """
        {
          "type" : "dispatcher_creation",
          "dispatcher" : \(dispatcher),
          "store" : "\(store)"
        }
        """
      )
    }
  }
  
  public func didDestroyDispatcher(store: AnyObject, dispatcher: Any) {
    let log = """
    {
      "type" : "dispatcher_destruction",
      "dispatcher" : \(dispatcher),
      "store" : "\(store)"
    }
    """
    queue.async {
      os_log("%@", log: self.dispatcherDestructionLog, type: .default, log)
    }
  }
  
}

