//
//  DispatcherContext.swift
//  VergeStore
//
//  Created by muukii on 2019/11/18.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public final class VergeStoreDispatcherContext<Dispatcher: Dispatching> {
  
  public typealias State = Dispatcher.State
  
  public let dispatcher: Dispatcher
  public let metadata: ActionMetadata
  private let parent: VergeStoreDispatcherContext<Dispatcher>?
  
  public var state: State {
    return dispatcher.targetStore.state
  }
  
  init(
    dispatcher: Dispatcher,
    metadata: ActionMetadata,
    parent: VergeStoreDispatcherContext<Dispatcher>?
  ) {
    self.dispatcher = dispatcher
    self.metadata = metadata
    self.parent = parent
  }
     
}

extension VergeStoreDispatcherContext {
  
  public var dispatch: Actions<Dispatcher> {
    return .init(base: dispatcher, parentContext: self)
  }
  
  public var commit: Mutations<Dispatcher> {
    return .init(base: dispatcher, context: self)
  }
}

extension VergeStoreDispatcherContext: CustomReflectable {
  
  public var customMirror: Mirror {
    Mirror(
      self,
      children: [
        "metadata": metadata,
        "parent" : parent as Any
      ],
      displayStyle: .struct
    )
  }
}

//extension VergeStoreDispatcherContext where State : StateType {
//
//  public func commit<Target>(
//    _ target: WritableKeyPath<State, Target>,
//    _ name: String = "",
//    _ file: StaticString = #file,
//    _ function: StaticString = #function,
//    _ line: UInt = #line,
//    _ inlineMutation: (inout Target) throws -> Void
//  ) rethrows {
//
//    try dispatcher.commit(target, name, file, function, line, self, inlineMutation)
//
//  }
//
//  public func commit<Target: _VergeStore_OptionalProtocol>(
//    _ target: WritableKeyPath<State, Target>,
//    _ name: String = "",
//    _ file: StaticString = #file,
//    _ function: StaticString = #function,
//    _ line: UInt = #line,
//    _ inlineMutation: (inout Target.Wrapped) throws -> Void
//  ) rethrows {
//
//    try dispatcher.commit(target, name, file, function, line, self, inlineMutation)
//
//  }
//}

//extension VergeStoreDispatcherContext where Dispatcher : ScopedDispatching {
//  
//  public var scopedState: Dispatcher.Scoped {
//    state[keyPath: dispatcher.selector]
//  }
//  
//  public func commitScoped(
//    _ name: String = "",
//    _ file: StaticString = #file,
//    _ function: StaticString = #function,
//    _ line: UInt = #line,
//    _ inlineMutation: (inout Dispatcher.Scoped) throws -> Void) rethrows {
//    
//    try dispatcher.commitScoped(name, file, function, line, self, inlineMutation)
//    
//  }
//}
//
//extension VergeStoreDispatcherContext where Dispatcher : ScopedDispatching, Dispatcher.Scoped : _VergeStore_OptionalProtocol {
//  
//  public func commitIfPresent(
//    _ name: String = "",
//    _ file: StaticString = #file,
//    _ function: StaticString = #function,
//    _ line: UInt = #line,
//    _ inlineMutation: (inout Dispatcher.Scoped.Wrapped) throws -> Void) rethrows {
//    
//    try dispatcher.commitScopedIfPresent(name, file, function, line, self, inlineMutation)
//    
//  }
//}
