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

public struct CommitLog: Encodable, Sendable {

  public let type: String = "commit"
  public let tookMilliseconds: Double
  public let traces: [MutationTrace]
  public let store: String

  public init(storeName: String, traces: [MutationTrace], time: CFTimeInterval) {
    self.store = storeName
    self.tookMilliseconds = time * 1000
    self.traces = traces
  }
}

public struct ActivityLog: Encodable, Sendable {
  
  public let type: String = "activity"
  public let trace: ActivityTrace
  public let store: String

  public init(storeName: String, trace: ActivityTrace) {
    self.store = storeName
    self.trace = trace
  }
}

public struct DidCreateDispatcherLog: Encodable, Sendable {
  
  public let type: String = "did_create_dispatcher"
  public let store: String
  public let dispatcher: String

  public init(storeName: String, dispatcherName: String) {
    self.store = storeName
    self.dispatcher = dispatcherName
  }
  
}

public struct DidDestroyDispatcherLog: Encodable, Sendable {
  
  public let type: String = "did_destroy_dispatcher"
  public let store: String
  public let dispatcher: String

  public init(storeName: String, dispatcherName: String) {
    self.store = storeName
    self.dispatcher = dispatcherName
  }
  
}

/// An object default implementation of VergeStoreLogger.
/// It uses `os_log` to print inside.
/// There are OSLog object each type of action.
/// You can turn off logging each OSLog object.
public struct DefaultStoreLogger: StoreLogger {
  
  public static var `default`: Self { 
    .init()
  }
  
  public let commitLog = OSLog(subsystem: "VergeStore", category: "Commit")
  public let activityLog = OSLog(subsystem: "VergeStore", category: "Activity")

  public let dispatcherCreationLog = OSLog(subsystem: "VergeStore", category: "Dispatcher_Creation")
  public let dispatcherDestructionLog = OSLog(subsystem: "VergeStore", category: "Dispatcher_Destruction")
    
  public init() {
    
  }
  
  private static let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    if #available(iOS 11.0, macOS 10.13, tvOS 11, watchOS 4, *) {
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    } else {
      encoder.outputFormatting = [.prettyPrinted]
    }
    return encoder
  }()
    
  public func didCommit(log: CommitLog, sender: AnyObject) {
    Task { [commitLog]in
      let string = String(data: try! DefaultStoreLogger.encoder.encode(log), encoding: .utf8)!
      os_log("%@", log: commitLog, type: .default, string)
    }
  }
  
  public func didSendActivity(log: ActivityLog, sender: AnyObject) {
    Task { [activityLog] in
      let string = String(data: try! DefaultStoreLogger.encoder.encode(log), encoding: .utf8)!
      os_log("%@", log: activityLog, type: .default, string)
    }
  }
   
  public func didCreateDispatcher(log: DidCreateDispatcherLog, sender: AnyObject) {    
    Task { [dispatcherCreationLog] in
      let string = String(data: try! DefaultStoreLogger.encoder.encode(log), encoding: .utf8)!
      os_log("%@", log: dispatcherCreationLog, type: .default, string)
    }
  }
  
  public func didDestroyDispatcher(log: DidDestroyDispatcherLog, sender: AnyObject) {
    Task { [dispatcherDestructionLog] in
      let string = String(data: try! DefaultStoreLogger.encoder.encode(log), encoding: .utf8)!
      os_log("%@", log: dispatcherDestructionLog, type: .default, string)
    }
  }
    
}

