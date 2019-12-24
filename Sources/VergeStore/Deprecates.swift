//
//  Deprecates.swift
//  VergeStore
//
//  Created by muukii on 2019/12/25.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

extension DispatcherContext {
  
  /// Dummy Method to work Xcode code completion
  @available(*, unavailable)
  public func accept(_ get: (Dispatcher) -> Never) -> Never { fatalError() }
  
  /// Run Mutation
  /// - Parameter get: returns Mutation
  @available(*, deprecated, renamed: "commit")
  public func accept<Mutation: MutationType>(_ get: (Dispatcher) -> Mutation) -> Mutation.Result where Mutation.State == State {
    commit(get)
  }
  
  /// Run Action
  @discardableResult
  @available(*, deprecated, renamed: "dispatch")
  public func accept<Action: ActionType>(_ get: (Dispatcher) -> Action) -> Action.Result where Action.Dispatcher == Dispatcher {
    dispatch(get)
  }
}

extension DispatcherType {
  
  /// Run Mutation
  /// - Parameter get: returns Mutation
  @available(*, deprecated, renamed: "commit")
  public func accept<Mutation: MutationType>(_ get: (Self) -> Mutation) -> Mutation.Result where Mutation.State == State {
    commit(get)
  }
  
  ///
  /// - Parameter get: Return Action object
  @discardableResult
  @available(*, deprecated, renamed: "dispatch")
  public func accept<Action: ActionType>(_ get: (Self) -> Action) -> Action.Result where Action.Dispatcher == Self {
    dispatch(get)
  }
}
