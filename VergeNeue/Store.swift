//
//  Store.swift
//  VergeNeue
//
//  Created by muukii on 2019/09/18.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public final class Store<State, Reducer: ReducerType>: StoreBase<State, Reducer> where Reducer.TargetState == State {
  
  public var state: State {
    storage.value
  }
  
  let storage: Storage<State>
  
  private let reducer: Reducer
  
  private let lock = NSLock()
  
  public init(
    state: State,
    reducer: Reducer
  ) {
    self.storage = .init(state)
    self.reducer = reducer
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
    storage.update { (state) in
      mutation.mutate(&state)
    }
  }
  
  public func makeScoped<ScopedState, ScopedOperations: ReducerType>(
    scope: WritableKeyPath<State, ScopedState>,
    reducer: ScopedOperations
  ) -> ScopedStore<State, ScopedState, ScopedOperations> where ScopedOperations.TargetState == ScopedState {
    
    let scopedStore = ScopedStore<State, ScopedState, ScopedOperations>(
      store: self,
      scopeSelector: scope,
      reducer: reducer
    )
    
    return scopedStore
  }
  
}
