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

public struct _Mutation<State> {
  
  let mutate: (inout State) -> Void
  
  public let metadata: MutationMetadata
  
  public init(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    mutate: @escaping (inout State) -> Void
  ) {
    self.mutate = mutate
    self.metadata = .init(name: name, file: file, function: function, line: line)
  }
}

public struct _Action<Store: StoreType, ReturnType> {
  
  let action: (StoreDispatchContext<Store>) -> ReturnType
  
  public let metadata: ActionMetadata
  
  public init(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    action: @escaping (StoreDispatchContext<Store>) -> ReturnType) {
    self.action = action
    self.metadata = .init(name: name, file: file, function: function, line: line)
    
  }
  
//  public func asAction() -> _Action<Reducer, ReturnType> {
//    return self
//  }
}

public final class StoreDispatchContext<Store: StoreType> {
  
  private let store: Store
  
  public var state: Store.State {
    return store.state
  }
  
  init(store: Store) {
    self.store = store
  }
  
  @discardableResult
  public func dispatch<ReturnType>(_ makeAction: (Store) -> _Action<Store, ReturnType>) -> ReturnType {
    store.dispatch(makeAction)
  }
  
  public func commit(_ makeMutation: (Store) -> _Mutation<Store.State>) {
    store.commit(makeMutation)
  }
}

public protocol StoreLogger {
  
  func willCommit(store: Any, state: Any, mutation: MutationMetadata)
  func didCommit(store: Any, state: Any, mutation: MutationMetadata)
  func didDispatch(store: Any, state: Any, action: ActionMetadata)
}

public protocol StoreType {
  
  associatedtype State
  var storage: Storage<State> { get }
  var logger: StoreLogger? { get }
  
  typealias Action<Return> = _Action<Self, Return>
  typealias Mutation = _Mutation<State>
}

open class StoreBase<State>: StoreType {
      
  public let storage: Storage<State>
  
  public private(set) var logger: StoreLogger?
  
  public init(initialState: State, logger: StoreLogger?) {
    self.storage = .init(initialState)
    self.logger = logger
  }
    
}

extension StoreType {
  
  public var state: State {
    storage.value
  }
  
  public func dispatch<Return>(_ makeAction: (Self) -> Action<Return>) -> Return {
    
    let context = StoreDispatchContext<Self>.init(store: self)
    let action = makeAction(self)
    let result = action.action(context)
    logger?.didDispatch(store: self, state: state, action: action.metadata)
    return result
  }
  
  public func commit(_ makeMutation: (Self) -> Mutation) {
    let mutation = makeMutation(self)
    
    logger?.willCommit(store: self, state: state, mutation: mutation.metadata)
    defer {
      logger?.didCommit(store: self, state: state, mutation: mutation.metadata)
    }
    
    storage.update { (state) in
      mutation.mutate(&state)
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

extension StoreBase: ObservableObject {
  public var objectWillChange: ObservableObjectPublisher {
    storage.objectWillChange
  }
}
  
#endif

