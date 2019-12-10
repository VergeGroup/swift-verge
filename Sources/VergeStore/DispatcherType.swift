//
//  Dispatching.swift
//  VergeStore
//
//  Created by muukii on 2019/12/03.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public protocol DispatcherType {
    
  associatedtype State
  typealias Store = StoreBase<State>
  typealias Mutation = AnyMutation<Self>
  typealias Action<Return> = AnyAction<Self, Return>
  var dispatchTarget: Store { get }
  
}

extension DispatcherType {
  
  ///
  /// - Parameter get: Return Mutation Object
  public func accept(_ get: (Self) -> Mutation) {
    let mutation = get(self)
    dispatchTarget.receive(
      context: Optional<VergeStoreDispatcherContext<Self>>.none,
      mutation: mutation
    )
  }
    
  ///
  /// - Parameter get: Return Action object
  @discardableResult
  public func accept<Return>(_ get: (Self) -> Action<Return>) -> Return {
    let action = get(self)
    let context = VergeStoreDispatcherContext<Self>.init(
      dispatcher: self,
      metadata: action.metadata,
      parent: nil
    )
    return action._action(context)
  }

}

public protocol ScopedDispatching: DispatcherType where State : StateType {
  associatedtype Scoped
  
  static var scopedStateKeyPath: WritableKeyPath<State, Scoped> { get }
}
