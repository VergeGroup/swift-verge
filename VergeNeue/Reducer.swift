//
//  Reducer.swift
//  VergeNeue
//
//  Created by muukii on 2019/09/22.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public protocol ScopedReducerType {
  
  associatedtype TargetState
  associatedtype SourceReducer: ModularReducerType
  
  typealias StoreType = ScopedStore<Self>
  
  typealias Mutation = _Mutation<TargetState>
  typealias Action<ReturnType> = _ScopedAction<Self, ReturnType>
  
  var scopeKeyPath: WritableKeyPath<SourceReducer.State, TargetState> { get }
}

public protocol ModularReducerType {
  associatedtype State
  associatedtype ParentReducer: ModularReducerType
  
  typealias Mutation = _Mutation<State>
  typealias Action<ReturnType> = _Action<Self, ReturnType>
  
  typealias StoreType = Store<Self>
  
  func makeInitialState() -> State
  
  func usingAdapters() -> [AdapterBase<Self>]
  
  func parentChanged(newState: ParentReducer.State, store: Store<Self>)
}

extension ModularReducerType {
  
  public func usingAdapters() -> [AdapterBase<Self>] {
    []
  }
  
  public func parentChanged(newState: ParentReducer.State, store: Store<Self>) {
    
  }
  
}

extension Never: ModularReducerType {
  public typealias State = Never
  public typealias ParentReducer = Never
  public func makeInitialState() -> Never {
    fatalError()
  }
  public func usingAdapters() -> [AdapterBase<Never>] {
    fatalError()
  }
}

extension ModularReducerType where ParentReducer == Never {
  public func parentChanged(newState: ParentReducer.State, store: Store<Self>) {}
}

public protocol ReducerType: ModularReducerType where ParentReducer == Never {
  
}
