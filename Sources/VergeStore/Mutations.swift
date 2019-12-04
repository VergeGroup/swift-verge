//
//  Mutations.swift
//  VergeStore
//
//  Created by muukii on 2019/12/04.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

/// An object to provide a group of Mutations
/// ```
/// extension Mutations where Base == MyDispatcher {
///
///   func continuousIncrement() {
///
///     descriptor.commit {
///       $0.count += 1
///     }
///   }
///}
///```
///
public struct Mutations<Base: Dispatching> {
  
  public let base: Base
  private let context: VergeStoreDispatcherContext<Base>?
  
  public var descriptor: MutationDescriptor<Base> {
    .init(base: base, context: context)
  }
  
  init(base: Base, context: VergeStoreDispatcherContext<Base>? = nil) {
    self.base = base
    self.context = context
  }
  
}

/// An object to describe the Mutation
/// The reason why we need this object,
/// Since we have several methods to run Commit, to hide these from outside of Dispatcher.
public struct MutationDescriptor<Base: Dispatching> {
  
  public let base: Base
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

extension MutationDescriptor where Base.State : StateType {
  
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

extension MutationDescriptor where Base : ScopedDispatching {
  
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

extension MutationDescriptor where Base : ScopedDispatching, Base.Scoped : _VergeStore_OptionalProtocol {
  
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
