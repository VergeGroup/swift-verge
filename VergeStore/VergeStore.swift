//
//  VergeStore.swift
//  VergeStore
//
//  Created by muukii on 2019/09/24.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public struct MutationMetadata {
  
  public let name: String
  public let file: StaticString
  public let function: StaticString
  public let line: UInt
  
}

public struct ActionMetadata {
  
  public let name: String
  public let file: StaticString
  public let function: StaticString
  public let line: UInt
  
}

public final class StoreDispatchContext<Store: StoreType> {
  
  public let store: Store
  
  public var state: Store.UsingState {
    return store.state
  }
  
  init(store: Store) {
    self.store = store
  }
  
  @discardableResult
  public func dispatch<ReturnType>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: (StoreDispatchContext<Store>) -> ReturnType
  ) -> ReturnType {
    
    store.dispatch(name, file, function, line, action)
  }
  
  public func commit(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ mutation: (inout Store.UsingState) -> Void
  ) {
    
    store.commit(name, file, function, line, mutation)
  }
}

public protocol StoreLogger {
  
  func willCommit(store: Any, state: Any, mutation: MutationMetadata)
  func didCommit(store: Any, state: Any, mutation: MutationMetadata)
  func didDispatch(store: Any, state: Any, action: ActionMetadata)
}

public protocol StoreType {
  
  associatedtype UsingState
  var storage: Storage<UsingState> { get }
  var logger: StoreLogger? { get }
  
}

open class StoreBase<State>: StoreType, Identifiable {
  
  public var id: ObjectIdentifier {
    .init(self)
  }
      
  public let storage: Storage<State>
  
  public private(set) var logger: StoreLogger?
  
  public init(initialState: State, logger: StoreLogger?) {
    self.storage = .init(initialState)
    self.logger = logger
  }
    
}

extension StoreType {
  
  public var state: UsingState {
    storage.value
  }
    
  @discardableResult
  public func dispatch<ReturnType>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: (StoreDispatchContext<Self>) -> ReturnType
  ) -> ReturnType {
    
    let metadata = ActionMetadata(name: name, file: file, function: function, line: line)
    
    let context = StoreDispatchContext<Self>.init(store: self)
    let result = action(context)
    logger?.didDispatch(store: self, state: state, action: metadata)
    return result
    
  }
  
  public func commit(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ mutation: (inout UsingState) -> Void
  ) {
    
    let metadata = MutationMetadata(name: name, file: file, function: function, line: line)
        
    logger?.willCommit(store: self, state: state, mutation: metadata)
    defer {
      logger?.didCommit(store: self, state: state, mutation: metadata)
    }
    
    storage.update { (state) in
      mutation(&state)
    }
  }
  
}

#if canImport(Combine)

import Combine

private var _associated: Void?

@available(iOS 13.0, *)
extension Storage: ObservableObject {
  
  public var objectWillChange: ObservableObjectPublisher {
    if let associated = objc_getAssociatedObject(self, &_associated) as? ObservableObjectPublisher {
      return associated
    } else {
      let associated = ObservableObjectPublisher()
      objc_setAssociatedObject(self, &_associated, associated, .OBJC_ASSOCIATION_RETAIN)
      
      add { _ in
        if Thread.isMainThread {
          associated.send()
        } else {
          DispatchQueue.main.async {
            associated.send()
          }
        }
      }
      
      return associated
    }
  }
}

@available(iOS 13, *)
extension StoreBase: ObservableObject {
  public var objectWillChange: ObservableObjectPublisher {
    storage.objectWillChange
  }
}
  
#endif

