//
// Copyright (c) 2019 muukii
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

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
  
  public func willCommit(store: AnyObject, state: Any, mutation: MutationMetadata, context: Any?) {
  }
  
  public func didCommit(store: AnyObject, state: Any, mutation: MutationMetadata, context: Any?, time: CFTimeInterval) {
    
    let message = """
    {
      "type" : "commit",
      "took": "\(time * 1000)ms"
      "mutation" : \(mutation),
      "context" : \(context as Any),
      "store" : "\(store)"
    }
    """
    
    queue.async {
      os_log("%@", log: self.commitLog, type: .default, message)
    }
  }
  
  public func didDispatch(store: AnyObject, state: Any, action: ActionMetadata, context: Any?) {
    let message = """
    {
      "type" : "dispatch",
      "action" : \(action),
      "context" : \(context as Any),
      "store" : "\(store)"
    }
    """
    queue.async {
      os_log("%@", log: self.dispatchLog, type: .default, message)
    }
  }
  
  public func didCreateDispatcher(store: AnyObject, dispatcher: Any) {
    let message = """
    {
      "type" : "dispatcher_creation",
      "dispatcher" : \(dispatcher),
      "store" : "\(store)"
    }
    """
    queue.async {
      os_log("%@", log: self.dispatcherCreationLog, type: .default, message)
    }
  }
  
  public func didDestroyDispatcher(store: AnyObject, dispatcher: Any) {
    let message = """
    {
      "type" : "dispatcher_destruction",
      "dispatcher" : \(dispatcher),
      "store" : "\(store)"
    }
    """
    queue.async {
      os_log("%@", log: self.dispatcherDestructionLog, type: .default, message)
    }
  }
  
}

