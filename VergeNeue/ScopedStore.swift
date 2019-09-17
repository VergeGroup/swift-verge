//
//  ScopedStore.swift
//  VergeNeue
//
//  Created by muukii on 2019/09/18.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public final class ScopedStore<SourceState, State, Reducer: ReducerType>: StoreBase<State, Reducer> where Reducer.TargetState == State {
  
  public var state: State {
    storage.value[keyPath: scopeSelector]
  }
  
  private let reducer: Reducer
  let storage: Storage<SourceState>
  private let scopeSelector: WritableKeyPath<SourceState, State>
  
  init<SourceOperations: ReducerType>(
    store: Store<SourceState, SourceOperations>,
    scopeSelector: WritableKeyPath<SourceState, State>,
    reducer: Reducer
  ) {
    
    self.storage = store.storage
    self.reducer = reducer
    self.scopeSelector = scopeSelector
    
  }
  
  @discardableResult
  public override func dispatch<ReturnType>(_ makeAction: (Reducer) -> Reducer.Action<ReturnType>) -> ReturnType {
    let context = DispatchContext<State, Reducer>.init(store: self)
    let action = makeAction(reducer)
    let result = action.action(context)
    return result
  }
  
  public override func commit(_ makeMutation: (Reducer) -> Reducer.Mutation) {
    let mutation = makeMutation(reducer)
    storage.update { (sourceState) in
      mutation.mutate(&sourceState[keyPath: scopeSelector])
    }
  }
}
