//
//  Reducer.swift
//  VergeNeue
//
//  Created by muukii on 2019/09/22.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public protocol ModularReducerType {
  associatedtype TargetState
  
  typealias Mutation = _Mutation<TargetState>
  typealias Action<ReturnType> = _Action<Self, ReturnType>
  
  typealias StoreType = Store<Self>
  typealias ScopedStoreType = ScopedStore<ParentReducer, Self>
  typealias DispatchContext = VergeNeue.DispatchContext<Self>
  
  func makeInitialState() -> TargetState
  
  associatedtype ParentReducer: ModularReducerType
  func parentChanged(newState: ParentReducer.TargetState)
}

extension Never: ModularReducerType {
  public typealias TargetState = Never
  public typealias ParentReducer = Never
  public func makeInitialState() -> Never {
    fatalError()
  }
}

extension ModularReducerType where ParentReducer == Never {
  public func parentChanged(newState: ParentReducer.TargetState) {}
}

public protocol ReducerType: ModularReducerType where ParentReducer == Never {
  
}
