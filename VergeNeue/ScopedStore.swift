//
//  ScopedStore.swift
//  VergeNeue
//
//  Created by muukii on 2019/09/18.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public final class ScopedStore<SourceReducer: ModularReducerType, Reducer: ModularReducerType>: StoreBase<Reducer> {
  
  public typealias SourceState = SourceReducer.TargetState
  
  public override var state: State {
    storage.value[keyPath: scopeSelector]
  }
  
  public let sourceStore: Store<SourceReducer>
  
  private let reducer: Reducer
  let storage: Storage<SourceState>
  private let scopeSelector: WritableKeyPath<SourceState, State>
  
  init(
    sourceStore: Store<SourceReducer>,
    scopeSelector: WritableKeyPath<SourceState, State>,
    reducer: Reducer
  ) {
    
    self.storage = sourceStore.storage
    self.sourceStore = sourceStore
    self.reducer = reducer
    self.scopeSelector = scopeSelector
    
  }
  
  @discardableResult
  public override func dispatch<ReturnType>(_ makeAction: (Reducer) -> Reducer.Action<ReturnType>) -> ReturnType {
    let context = DispatchContext<Reducer>.init(store: self)
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
