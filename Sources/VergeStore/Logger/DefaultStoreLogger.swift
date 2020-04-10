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

public struct CommitLog: Encodable {
  
  public let type: String = "commit"
  public let tookMilliseconds: Double
  public let mutation: MutationMetadata
  public let store: String

  @inlinable
  public init(store: AnyObject, mutation: MutationMetadata, time: CFTimeInterval) {
    self.store = String(reflecting: store)
    self.tookMilliseconds = time * 1000
    self.mutation = mutation
  }
}

public struct DispatchLog: Encodable {
  
  public let type: String = "dispatch"
  public let action: ActionMetadata
  public let store: String
  
  @inlinable
  public init(store: AnyObject, state: Any, action: ActionMetadata) {
    self.store = String(reflecting: store)
    self.action = action
  }
}

public struct DidCreateDispatcherLog: Encodable {
  
  public let type: String = "did_create_dispatcher"
  public let store: String
  public let dispatcher: String
  
  @inlinable
  public init(store: AnyObject, dispatcher: Any) {
    self.store = String(reflecting: store)
    self.dispatcher = String(reflecting: dispatcher)
  }
  
}

public struct DidDestroyDispatcherLog: Encodable {
  
  public let type: String = "did_destroy_dispatcher"
  public let store: String
  public let dispatcher: String
  
  @inlinable
  public init(store: AnyObject, dispatcher: Any) {
    self.store = String(reflecting: store)
    self.dispatcher = String(reflecting: dispatcher)
  }
  
}

/// An object default implementation of VergeStoreLogger.
/// It uses `os_log` to print inside.
/// There are OSLog object each type of action.
/// You can turn off logging each OSLog object.
public final class DefaultStoreLogger: StoreLogger {
  
  public static let shared = DefaultStoreLogger()
  
  public let commitLog = OSLog(subsystem: "VergeStore", category: "Commit")
  public let dispatchLog = OSLog(subsystem: "VergeStore", category: "Dispatch")
  public let dispatcherCreationLog = OSLog(subsystem: "VergeStore", category: "Dispatcher_Creation")
  public let dispatcherDestructionLog = OSLog(subsystem: "VergeStore", category: "Dispatcher_Descruction")
  
  let queue = DispatchQueue(label: "logger")
  
  public init() {
    
  }
  
  private static let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    if #available(iOS 11.0, macOS 10.13, *) {
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    } else {
      encoder.outputFormatting = [.prettyPrinted]
    }
    return encoder
  }()
    
  public func didCommit(log: CommitLog) {
    queue.async {
      let string = String(data: try! DefaultStoreLogger.encoder.encode(log), encoding: .utf8)!
      os_log("%@", log: self.commitLog, type: .default, string)
    }
  }
  
  public func didDispatch(log: DispatchLog) {
    queue.async {
      let string = String(data: try! DefaultStoreLogger.encoder.encode(log), encoding: .utf8)!
      os_log("%@", log: self.dispatchLog, type: .default, string)
    }
  }
  
  public func didCreateDispatcher(log: DidCreateDispatcherLog) {
    queue.async {
      let string = String(data: try! DefaultStoreLogger.encoder.encode(log), encoding: .utf8)!
      os_log("%@", log: self.dispatcherCreationLog, type: .default, string)
    }
  }
  
  public func didDestroyDispatcher(log: DidDestroyDispatcherLog) {
    queue.async {
      let string = String(data: try! DefaultStoreLogger.encoder.encode(log), encoding: .utf8)!
      os_log("%@", log: self.dispatcherDestructionLog, type: .default, string)
    }
  }
    
}

