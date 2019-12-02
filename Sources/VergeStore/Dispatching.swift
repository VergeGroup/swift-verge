//
//  Dispatching.swift
//  VergeStore
//
//  Created by muukii on 2019/12/03.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public struct Mutations<Base: Dispatching> {
  
  let base: Base
  private let context: VergeStoreDispatcherContext<Base>?
  
  init(base: Base, context: VergeStoreDispatcherContext<Base>? = nil) {
    self.base = base
    self.context = context
  }
  
  public func commit(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ inlineMutation: (inout Base.State) throws -> Void
  ) rethrows {
    
    let metadata = MutationMetadata(name: name, file: file, function: function, line: line)
    
    try base.targetStore.receive(
      context: context,
      metadata: metadata,
      mutation: inlineMutation
    )
    
  }
  
}

extension Mutations where Base.State : StateType {
  
  public func commit<Target>(
    _ target: WritableKeyPath<Base.State, Target>,
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ inlineMutation: (inout Target) throws -> Void
  ) rethrows {
    
    let metadata = MutationMetadata(name: name, file: file, function: function, line: line)
    
    try base.targetStore.receive(
      context: context,
      metadata: metadata,
      mutation: { ( state: inout Base.State) in
        try state.update(target: target, update: inlineMutation)
    })
    
  }
  
  public func commit<Target: _VergeStore_OptionalProtocol>(
    _ target: WritableKeyPath<Base.State, Target>,
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ inlineMutation: (inout Target.Wrapped) throws -> Void
  ) rethrows {
    
    let metadata = MutationMetadata(name: name, file: file, function: function, line: line)
    
    try base.targetStore.receive(
      context: context,
      metadata: metadata,
      mutation: { ( state: inout Base.State) in
        try state.update(target: target, update: inlineMutation)
    })
    
  }
}

extension Mutations where Base : ScopedDispatching {
  
  public func commitScoped(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ inlineMutation: (inout Base.Scoped) throws -> Void) rethrows {
    
    try self.commit(
      base.selector,
      name,
      file,
      function,
      line,
      inlineMutation
    )
    
  }
  
}

extension Mutations where Base : ScopedDispatching, Base.Scoped : _VergeStore_OptionalProtocol {
  
  public func commitScopedIfPresent(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ inlineMutation: (inout Base.Scoped.Wrapped) throws -> Void) rethrows {
    
    try self.commit(
      base.selector,
      name,
      file,
      function,
      line,
      inlineMutation
    )
    
  }
  
}


public struct Actions<Base: Dispatching> {
  
  let base: Base
  
  init(base: Base) {
    self.base = base
  }
  
  @discardableResult
  public func dispatch<ReturnType>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ inlineAction: (VergeStoreDispatcherContext<Base>) throws -> ReturnType
  ) rethrows -> ReturnType {
    
    let metadata = ActionMetadata(name: name, file: file, function: function, line: line)
    
    let context = VergeStoreDispatcherContext<Base>.init(dispatcher: base, metadata: metadata)
    let result = try inlineAction(context)
    base.targetStore.logger?.didDispatch(
      store: base.targetStore,
      state: base.targetStore.state,
      action: metadata,
      context: context
    )
    
    return result
    
  }
  
}

public protocol Dispatching {
    
  associatedtype State
  typealias Store = VergeDefaultStore<State>
  var targetStore: Store { get }
}

extension Dispatching {
  
  public typealias Hoge = Mutations<Self>
    
  public var dispatch: Actions<Self> {
    return .init(base: self)
  }
  
  public var commit: Mutations<Self> {
    return .init(base: self)
  }
}

public protocol ScopedDispatching: Dispatching where State : StateType {
  associatedtype Scoped
  
  var selector: WritableKeyPath<State, Scoped> { get }
}
