//
//  Store.swift
//  VergeNeue
//
//  Created by muukii on 2019/09/18.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

open class Store<Reducer: ModularReducerType>: StoreBase<Reducer> {
    
  public typealias State = Reducer.TargetState
  
  public final override var state: State {
    storage.value
  }
  
  let storage: Storage<State>
  
  private let reducer: Reducer
  
  private let lock = NSLock()
  
  private var _deinit: () -> Void = {}
  
  private let logger: StoreLogger?
      
  public init(
    reducer: Reducer,
    logger: StoreLogger? = nil
  ) {
    self.storage = .init(reducer.makeInitialState())
    self.reducer = reducer
    self.logger = logger
    
    super.init()
    #if DEBUG
    print("Init", self)
    #endif
  }
  
  public convenience init<ParentReducer: ReducerType>(
    reducer: Reducer,
    registerParent parentStore: Store<ParentReducer>,
    logger: StoreLogger? = nil
  )
    where Reducer.ParentReducer == ParentReducer
  {
            
    self.init(reducer: reducer, logger: logger)
    
    let parentSubscripton = parentStore.storage.add { [weak self] (state) in
      self?.notify(newParentState: state)
    }
    
    notifyCurrent: do {
      notify(newParentState: parentStore.storage.value)      
    }
    
    self._deinit = { [weak storage = parentStore.storage] in
      storage?.remove(subscriber: parentSubscripton)
    }
    
  }
  
  deinit {
    #if DEBUG
    print("Deinit", self)
    #endif
    _deinit()
  }
  
  private func notify(newParentState: Reducer.ParentReducer.TargetState) {
    reducer.parentChanged(newState: newParentState)
  }

  @discardableResult
  public final override func dispatch<ReturnType>(_ makeAction: (Reducer) -> Reducer.Action<ReturnType>) -> ReturnType {
    let context = DispatchContext<Reducer>.init(store: self)
    let action = makeAction(reducer)
    let result = action.action(context)
    logger?.didDispatch(store: self, state: state, action: action.metadata)
    return result
  }
  
  public final override func commit(_ makeMutation: (Reducer) -> Reducer.Mutation) {
            
    let mutation = makeMutation(reducer)
    
    logger?.willCommit(store: self, state: state, mutation: mutation.metadata)
    defer {
      logger?.didCommit(store: self, state: state, mutation: mutation.metadata)
    }
    
    storage.update { (state) in
      mutation.mutate(&state)
    }
  }
  
  public final func makeScoped<ScopedState, ScopedReducer: ModularReducerType>(
    scope: WritableKeyPath<State, ScopedState>,
    reducer: ScopedReducer
  ) -> ScopedStore<Reducer, ScopedReducer> where ScopedReducer.TargetState == ScopedState {
    
    let scopedStore = ScopedStore<Reducer, ScopedReducer>(
      sourceStore: self,
      scopeSelector: scope,
      reducer: reducer
    )
    
    return scopedStore
  }
  
}
