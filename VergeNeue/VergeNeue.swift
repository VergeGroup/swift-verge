import Foundation

public struct _Mutation<State> {
  
  let mutate: (inout State) -> Void
  
  public init(mutate: @escaping (inout State) -> Void) {
    self.mutate = mutate
  }
}

public struct _Action<State, Reducer: ReducerType, ReturnType> where Reducer.TargetState == State {
  
  let action: (DispatchContext<State, Reducer>) -> ReturnType
  
  public init(action: @escaping (DispatchContext<State, Reducer>) -> ReturnType) {
    self.action = action
  }
}

public protocol ReducerType {
  associatedtype TargetState
  
  typealias Mutation = _Mutation<TargetState>
  typealias Action<ReturnType> = _Action<TargetState, Self, ReturnType>
  
  typealias StoreType = Store<TargetState, Self>
  typealias ScopedStoreType<RootState> = ScopedStore<RootState, TargetState, Self>
  typealias DispatchContext = VergeNeue.DispatchContext<TargetState, Self>
}

public final class DispatchContext<State, Reducer: ReducerType> where Reducer.TargetState == State {
  
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

