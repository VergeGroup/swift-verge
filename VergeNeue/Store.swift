//
//  Store.swift
//  VergeNeue
//
//  Created by muukii on 2019/09/18.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public final class Store<State, Reducer: ModularReducerType>: StoreBase<State, Reducer> where Reducer.TargetState == State {
  
  public var state: State {
    storage.value
  }
  
  let storage: Storage<State>
  
  private let reducer: Reducer
  
  private let lock = NSLock()
  
  private var _deinit: () -> Void = {}
    
  public init(
    state: State,
    reducer: Reducer
  ) {
    self.storage = .init(state)
    self.reducer = reducer
  }
  
  public convenience init<ParentState, ParentReducer: ReducerType>(
    state: State,
    reducer: Reducer,
    registerParent parentStore: Store<ParentState, ParentReducer>
  )
    where Reducer.ParentState == ParentState
  {
    
    self.init(state: state, reducer: reducer)
    
    let parentSubscripton = parentStore.storage.add { [weak self] (state) in
      self?.notify(newParentState: state)
    }
    
    self._deinit = { [weak storage = parentStore.storage] in
      storage?.remove(subscriber: parentSubscripton)
    }
    
    parentStore.register(store: self, for: "Foo")
  }
  
  deinit {
   _deinit()
  }
  
  private func notify(newParentState: Reducer.ParentState) {
    reducer.parentChanged(newState: newParentState)
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
  
  public func makeScoped<ScopedState, ScopedReducer: ModularReducerType>(
    scope: WritableKeyPath<State, ScopedState>,
    reducer: ScopedReducer
  ) -> ScopedStore<State, Reducer, ScopedState, ScopedReducer> where ScopedReducer.TargetState == ScopedState {
    
    let scopedStore = ScopedStore<State, Reducer, ScopedState, ScopedReducer>(
      parentStore: self,
      scopeSelector: scope,
      reducer: reducer
    )
    
    return scopedStore
  }
  
}
