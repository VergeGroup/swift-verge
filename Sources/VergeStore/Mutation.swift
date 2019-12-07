//
//  Mutation.swift
//  VergeStoreDemoSwiftUI
//
//  Created by muukii on 2019/12/08.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public struct AnyMutation<From: DispatcherType> {
  
  let _mutate: (inout From.State) -> Void
  
  public let metadata: MutationMetadata
  
  public init(
    _ name: StaticString = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    mutate: @escaping (inout From.State) -> Void
  ) {
    
    self.metadata = .init(name: name, file: file, function: function, line: line)
    self._mutate = mutate
  }
  
}

extension AnyMutation {
  
  public static func commit(
    _ name: StaticString = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    inlineMutation: @escaping (inout From.State) -> Void
  ) -> Self {
    
    self.init(name, file, function, line, mutate: inlineMutation)
    
  }
  
}

extension AnyMutation where From.State : StateType {
  
  public static func commit<Target>(
    _ target: WritableKeyPath<From.State, Target>,
    _ name: StaticString = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    inlineMutation: @escaping (inout Target) -> Void
  ) -> Self {
        
    AnyMutation.init(name, file, function, line) { (state: inout From.State) in
      state.update(target: target, update: inlineMutation)
    }
           
  }
  
  public static func commitIfPresent<Target: _VergeStore_OptionalProtocol>(
    _ target: WritableKeyPath<From.State, Target>,
    _ name: StaticString = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    inlineMutation: @escaping (inout Target.Wrapped) -> Void
  ) -> Self {
    
    AnyMutation.init(name, file, function, line) { (state: inout From.State) in
      state.updateIfPresent(target: target, update: inlineMutation)
    }
    
  }
}

extension AnyMutation where From : ScopedDispatching {
  
  public static func commitScoped(
    _ name: StaticString = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    inlineMutation: @escaping (inout From.Scoped) -> Void
  ) -> Self {
    
    self.commit(
      From.scopedStateKeyPath,
      name,
      file,
      function,
      line,
      inlineMutation: inlineMutation
    )
    
  }
  
}

extension AnyMutation where From : ScopedDispatching, From.Scoped : _VergeStore_OptionalProtocol {
  
  public static func commitScopedIfPresent(
    _ name: StaticString = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    inlineMutation: @escaping  (inout From.Scoped.Wrapped) -> Void) -> Self {
    
    self.commitIfPresent(
      From.scopedStateKeyPath,
      name,
      file,
      function,
      line,
      inlineMutation: inlineMutation
    )
    
  }
  
}

