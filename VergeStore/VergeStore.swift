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

public protocol VergeStoreLogger {
  
  func willCommit(store: AnyObject, state: Any, mutation: MutationMetadata, context: AnyObject?)
  func didCommit(store: AnyObject, state: Any, mutation: MutationMetadata, context: AnyObject?)
  func didDispatch(store: AnyObject, state: Any, action: ActionMetadata, context: AnyObject?)
  
  func didCreateDispatcher(store: AnyObject, dispatcher: Any)
  func didDestroyDispatcher(store: AnyObject, dispatcher: Any)
  
  func didTakeTimeToCommit(store: AnyObject, state: Any, mutation: MutationMetadata, time: CFTimeInterval)
}

open class VergeDefaultStore<State>: CustomReflectable {
  
  public typealias DispatcherType = Dispatcher<State>
  
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
  
  func receive<FromDispatcher: Dispatching>(
    context: VergeStoreDispatcherContext<FromDispatcher>?,
    metadata: MutationMetadata,
    mutation: (inout State) throws -> Void
  ) rethrows {
    
    logger?.willCommit(store: self, state: self.state, mutation: metadata, context: context)
    defer {
      logger?.didCommit(store: self, state: self.state, mutation: metadata, context: context)
    }
    
    let startedTime = CFAbsoluteTimeGetCurrent()
    try storage.update { (state) in
      try mutation(&state)
    }
    let elapsed = CFAbsoluteTimeGetCurrent() - startedTime
    
    logger?.didTakeTimeToCommit(
      store: self,
      state: self.state,
      mutation: metadata,
      time: elapsed
    )
       
  }
  
  public var customMirror: Mirror {
    Mirror(
      self,
      children: [
        "state": state
      ],
      displayStyle: .struct
    )
  }
      
}

public protocol Dispatching {
  associatedtype State
  typealias Store = VergeDefaultStore<State>
  var targetStore: Store { get }
}

extension Dispatching {
  
  @discardableResult
  public func dispatch<ReturnType>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: (VergeStoreDispatcherContext<Self>) throws -> ReturnType
  ) rethrows -> ReturnType {
    
    let metadata = ActionMetadata(name: name, file: file, function: function, line: line)
    
    let context = VergeStoreDispatcherContext<Self>.init(dispatcher: self)
    let result = try action(context)
    targetStore.logger?.didDispatch(store: targetStore, state: targetStore.state, action: metadata, context: context)
    return result
    
  }
  
  public func commit(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ context: VergeStoreDispatcherContext<Self>? = nil,
    _ mutation: (inout State) throws -> Void
  ) rethrows {
    
    let metadata = MutationMetadata(name: name, file: file, function: function, line: line)
    
    try targetStore.receive(
      context: context,
      metadata: metadata,
      mutation: mutation
    )
    
  }
}

open class Dispatcher<State>: Dispatching {
  
  public typealias Context = VergeStoreDispatcherContext<Dispatcher<State>>
  
  public let targetStore: Store
  
  private var logger: VergeStoreLogger? {
    targetStore.logger
  }
  
  public init(target store: Store) {
    self.targetStore = store
    
    logger?.didCreateDispatcher(store: store, dispatcher: self)
  }
  
  deinit {
    logger?.didDestroyDispatcher(store: targetStore, dispatcher: self)
  }
  

  
  
}

public protocol _VergeStore_OptionalProtocol {
  associatedtype Wrapped
  var _vergestore_wrappedValue: Wrapped? { get set }
}

extension Optional: _VergeStore_OptionalProtocol {
  
  public var _vergestore_wrappedValue: Wrapped? {
    get {
      return self
    }
    mutating set {
      self = newValue
    }
  }
}

public protocol ScopedDispatching: Dispatching {
  associatedtype Scoped
  
  var selector: WritableKeyPath<State, Scoped> { get }
}

extension ScopedDispatching {
  
  public func commitScoped(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ context: VergeStoreDispatcherContext<Self>? = nil,
    _ mutation: (inout Scoped) throws -> Void) rethrows {
    
    let metadata = MutationMetadata(name: name, file: file, function: function, line: line)
    
    try targetStore.receive(
      context: context,
      metadata: metadata,
      mutation: { ( state: inout State) in
        
        try mutation(&state[keyPath: selector])
    })
    
  }
  
}

extension ScopedDispatching where Scoped : _VergeStore_OptionalProtocol {
  
  public func commitScopedIfPresent(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ context: VergeStoreDispatcherContext<Self>? = nil,
    _ mutation: (inout Scoped.Wrapped) throws -> Void) rethrows {
    
    let metadata = MutationMetadata(name: name, file: file, function: function, line: line)
    
    try targetStore.receive(
      context: context,
      metadata: metadata,
      mutation: { ( state: inout State) in
                                
        guard state[keyPath: selector]._vergestore_wrappedValue != nil else { return }
        try mutation(&state[keyPath: selector]._vergestore_wrappedValue!)
    })
    
  }
  
}

public final class VergeStoreDispatcherContext<Dispatcher: Dispatching> {
  
  public let dispatcher: Dispatcher
  
  public var state: Dispatcher.State {
    return dispatcher.targetStore.state
  }
  
  init(dispatcher: Dispatcher) {
    self.dispatcher = dispatcher
  }
    
  public func commit(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ mutation: (inout Dispatcher.State) -> Void
  ) {
    
    dispatcher.commit(name, file, function, line, self, mutation)
  }
}

extension VergeStoreDispatcherContext where Dispatcher : ScopedDispatching {
  
  public func commitScoped(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ mutation: (inout Dispatcher.Scoped) throws -> Void) rethrows {

    try dispatcher.commitScoped(name, file, function, line, self, mutation)
    
  }
}

extension VergeStoreDispatcherContext where Dispatcher : ScopedDispatching, Dispatcher.Scoped : _VergeStore_OptionalProtocol {
  
  public func commitIfPresent(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ mutation: (inout Dispatcher.Scoped.Wrapped) throws -> Void) rethrows {
    
    try dispatcher.commitScopedIfPresent(name, file, function, line, self, mutation)
    
  }
}

#if canImport(Combine)

import Foundation
import Combine

private var _associated: Void?

@available(iOS 13.0, macOS 10.15, *)
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

@available(iOS 13.0, macOS 10.15, *)
extension VergeDefaultStore: ObservableObject {
  public var objectWillChange: ObservableObjectPublisher {
    storage.objectWillChange
  }
}

@available(iOS 13.0, macOS 10.15, *)
extension Dispatcher: ObservableObject {

}

#endif
