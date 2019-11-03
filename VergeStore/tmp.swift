//
//  tmp.swift
//  VergeStore
//
//  Created by muukii on 2019/11/04.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public protocol VergeStoreLogger {
  
  func willCommit(store: Any, state: Any, mutation: MutationMetadata)
  func didCommit(store: Any, state: Any, mutation: MutationMetadata)
  func didDispatch(store: Any, state: Any, action: ActionMetadata)
}

open class VergeDefaultStore<State> {
  
  public var state: State {
    storage.value
  }
  
  let storage: Storage<State>
  
  public private(set) var logger: VergeStoreLogger?
  
  public init(
    initialState: State,
    logger: VergeStoreLogger?
  ) {
    
    self.storage = .init(initialState)
    self.logger = logger
    
  }
      
}

open class Dispatcher<State> {
  
  public typealias Store = VergeDefaultStore<State>
  
  public let targetStore: Store
  
  public init(target store: Store) {
    self.targetStore = store
  }
  
  @discardableResult
  public func dispatch<ReturnType>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: (DispatchingActionContext<State>) throws -> ReturnType
  ) rethrows -> ReturnType {
    
    let metadata = ActionMetadata(name: name, file: file, function: function, line: line)
    
    let context = DispatchingActionContext<State>.init(dispatcher: self)
    let result = try action(context)
    targetStore.logger?.didDispatch(store: self, state: targetStore.state, action: metadata)
    return result
    
  }
  
  public func commit(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ mutation: (inout State) throws -> Void
  ) rethrows {
    
    let metadata = MutationMetadata(name: name, file: file, function: function, line: line)
    
    targetStore.logger?.willCommit(store: self, state: targetStore.state, mutation: metadata)
    defer {
      targetStore.logger?.didCommit(store: self, state: targetStore.state, mutation: metadata)
    }
    
    try targetStore.storage.update { (state) in
      try mutation(&state)
    }
  }
  
}

public final class DispatchingActionContext<State> {
  
  public let dispatcher: Dispatcher<State>
  
  public var state: State {
    return dispatcher.targetStore.state
  }
  
  init(dispatcher: Dispatcher<State>) {
    self.dispatcher = dispatcher
  }
  
  @discardableResult
  public func dispatch<ReturnType>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: (DispatchingActionContext<State>) -> ReturnType
  ) -> ReturnType {
    
    dispatcher.dispatch(name, file, function, line, action)
  }
  
  public func commit(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ mutation: (inout State) -> Void
  ) {
    
    dispatcher.commit(name, file, function, line, mutation)
  }
}

#if canImport(Combine)

import Foundation
import Combine

@available(iOS 13, *)
extension VergeDefaultStore: ObservableObject {
  public var objectWillChange: ObservableObjectPublisher {
    storage.objectWillChange
  }
}

@available(iOS 13, *)
extension Dispatcher: ObservableObject {

}

#endif
