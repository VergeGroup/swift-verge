import Foundation

public struct _Mutation<State> {
  
  let mutate: (inout State) -> Void
  
  public init(mutate: @escaping (inout State) -> Void) {
    self.mutate = mutate
  }
}

public struct _Action<State, Reducer: ModularReducerType, ReturnType> where Reducer.TargetState == State {
  
  let action: (DispatchContext<State, Reducer>) -> ReturnType
  
  public init(action: @escaping (DispatchContext<State, Reducer>) -> ReturnType) {
    self.action = action
  }
}

public protocol ModularReducerType {
  associatedtype TargetState
  
  typealias Mutation = _Mutation<TargetState>
  typealias Action<ReturnType> = _Action<TargetState, Self, ReturnType>
  
  typealias StoreType = Store<TargetState, Self>
  typealias ScopedStoreType<RootState, RootReducer: ModularReducerType> = ScopedStore<RootState, RootReducer, TargetState, Self> where RootState == RootReducer.TargetState
  typealias DispatchContext = VergeNeue.DispatchContext<TargetState, Self>
    
  associatedtype ParentState
  func parentChanged(newState: ParentState)
}

extension ModularReducerType where ParentState == Void {
  public func parentChanged(newState: ParentState) {}
}

public protocol ReducerType: ModularReducerType where ParentState == Void {
    
}

public final class DispatchContext<State, Reducer: ModularReducerType> where Reducer.TargetState == State {
  
  private let store: StoreBase<State, Reducer>
  
  init(store: StoreBase<State, Reducer>) {
    self.store = store
  }
  
  @discardableResult
  public func dispatch<ReturnType>(_ makeAction: (Reducer) -> Reducer.Action<ReturnType>) -> ReturnType {
    store.dispatch(makeAction)
  }
  
  public func commit(_ makeMutation: (Reducer) -> Reducer.Mutation) {
    store.commit(makeMutation)
  }
}

