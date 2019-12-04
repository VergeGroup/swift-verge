//
//  Dispatching.swift
//  VergeStore
//
//  Created by muukii on 2019/12/03.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public protocol Dispatching {
    
  associatedtype State
  typealias Store = VergeDefaultStore<State>
  var targetStore: Store { get }
}

extension Dispatching {
      
  public var dispatch: Actions<Self> {
    return .init(base: self, parentContext: nil)
  }
  
  public var commit: Mutations<Self> {
    return .init(base: self)
  }
}

public protocol ScopedDispatching: Dispatching where State : StateType {
  associatedtype Scoped
  
  var selector: WritableKeyPath<State, Scoped> { get }
}
