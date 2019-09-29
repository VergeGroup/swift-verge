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

public final class StoreDispatchContext<Store: StateNodeType> {
  
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

public protocol StateNodeLogger {
  
  func willCommit(store: Any, state: Any, mutation: MutationMetadata)
  func didCommit(store: Any, state: Any, mutation: MutationMetadata)
  func didDispatch(store: Any, state: Any, action: ActionMetadata)
}

public protocol StateNodeType {
  
  associatedtype UsingState
  var storage: Storage<UsingState> { get }
  var logger: StateNodeLogger? { get }
  
}

@available(*, deprecated, renamed: "StateNode")
public typealias StoreBase<State> = StateNode<State>

open class AnyStateNode: Identifiable {
  
  public var id: ObjectIdentifier {
    .init(self)
  }
  
  public private(set) weak var parent: AnyStateNode?
  
  private var childNodes: [AnyStateNode] = .init()
  
  public func add(child node: AnyStateNode) {
    childNodes.append(node)
    node.parent = self
  }
  
  public func remove(child node: AnyStateNode) {
    childNodes.removeAll { $0 === node }
    node.parent = nil
  }
    
  public func removeFromParent() {
    parent?.remove(child: self)
  }
}

open class StateNode<State>: AnyStateNode, StateNodeType {
    
  public let storage: Storage<State>
    
  public private(set) var logger: StateNodeLogger?
  
  public init(initialState: State, logger: StateNodeLogger?) {
    self.storage = .init(initialState)
    self.logger = logger
    super.init()
  }

}

extension StateNodeType {
  
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
extension StateNode: ObservableObject {
  public var objectWillChange: ObservableObjectPublisher {
    storage.objectWillChange
  }
}
  
#endif

