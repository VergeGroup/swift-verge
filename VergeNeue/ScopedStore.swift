//
//  ScopedStore.swift
//  VergeNeue
//
//  Created by muukii on 2019/09/18.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public final class ScopedStore<Reducer: ScopedReducerType> {
  
  public typealias Action = Reducer.ScopedAction
  public typealias State = Reducer.TargetState
  public typealias SourceState = Reducer.SourceReducer.State
  
  public var state: State {
    storage.value[keyPath: scopeSelector]
  }
    
  private let reducer: Reducer
  let storage: Storage<Reducer.SourceReducer.State>
  private let scopeSelector: WritableKeyPath<SourceState, State>
  
  init(
    sourceStore: Store<Reducer.SourceReducer>,
    scopeSelector: WritableKeyPath<SourceState, State>,
    reducer: Reducer
  ) {
    
    self.storage = sourceStore.storage
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
