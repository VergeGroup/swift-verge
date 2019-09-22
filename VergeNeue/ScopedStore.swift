//
//  ScopedStore.swift
//  VergeNeue
//
//  Created by muukii on 2019/09/18.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public final class ScopedStore<Reducer: ModularReducerType> {
  
  public typealias Action = Reducer.ScopedAction
  public typealias State = Reducer.TargetState
  public typealias SourceState = Reducer.ParentReducer.TargetState
  
  public var state: State {
    storage.value[keyPath: scopeSelector]
  }
  
  public let sourceStore: Store<Reducer.ParentReducer>
  
  private let reducer: Reducer
  let storage: Storage<Reducer.ParentReducer.TargetState>
  private let scopeSelector: WritableKeyPath<SourceState, State>
  
  init(
    sourceStore: Store<Reducer.ParentReducer>,
    scopeSelector: WritableKeyPath<SourceState, State>,
    reducer: Reducer
  ) {
    
    self.storage = sourceStore.storage
    self.sourceStore = sourceStore
    self.reducer = reducer
    self.scopeSelector = scopeSelector
    
  }
  
  @discardableResult
  public func dispatch<ReturnType>(_ makeAction: (Reducer) -> Reducer.ScopedAction<ReturnType>) -> ReturnType {
    let context = ScopedDispatchContext<Reducer>.init(store: self)
    let action = makeAction(reducer)
    let result = action.action(context)
    return result
  }
  
  public func commit(_ makeMutation: (Reducer) -> Reducer.Mutation) {
    let mutation = makeMutation(reducer)
    storage.update { (sourceState) in
      mutation.mutate(&sourceState[keyPath: scopeSelector])
    }
  }
}
