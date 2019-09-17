
import Foundation

public struct _Mutation<State> {
  
  let mutate: (inout State) -> Void
  
  public init(mutate: @escaping (inout State) -> Void) {
    self.mutate = mutate
  }
}

public struct _Action<State, MutationsType, ActionsType: Actions, ReturnType> where MutationsType.State == State, ActionsType.State == State, ActionsType.MutationsType == MutationsType {
  
  let action: (DispatchContext<State, MutationsType, ActionsType>) -> ReturnType
  
  public init(action: @escaping (DispatchContext<State, MutationsType, ActionsType>) -> ReturnType) {
    self.action = action
  }
}

public protocol Mutations {
  associatedtype State
  typealias Mutation = _Mutation<State>
  
}

public protocol Actions {
  associatedtype MutationsType: Mutations
  associatedtype State where MutationsType.State == State
  typealias Action<ReturnType> = _Action<State, MutationsType, Self, ReturnType>
}

public final class DispatchContext<State, MutationsType, ActionsType: Actions> where MutationsType.State == State, ActionsType.State == State, ActionsType.MutationsType == MutationsType {
  
  private let store: Store<State, MutationsType, ActionsType>
  
  init(store: Store<State, MutationsType, ActionsType>) {
    self.store = store
  }
  
  public func dispatch<ReturnType>(_ makeAction: (ActionsType) -> ActionsType.Action<ReturnType>) -> ReturnType {
    store.dispatch(makeAction)
  }
  
  public func commit(_ makeMutation: (MutationsType) -> MutationsType.Mutation) {
    store.commit(makeMutation)
  }
}

public class StoreBase {
  
  private var stores: [String : StoreBase] = [:]
  
  func register<Store: StoreBase>(store: Store, for key: String) {
    stores[key] = store
  }
}


public final class Store<State, MutationsType, ActionsType: Actions>: StoreBase where
  MutationsType.State == State,
  ActionsType.State == State,
  ActionsType.MutationsType == MutationsType
{
  
  public var state: State {
    lock.lock()
    defer {
      lock.unlock()
    }
    return nonatomicState
  }
  
  private var nonatomicState: State
  
  private let mutations: MutationsType
  private let actions: ActionsType
  
  private let lock = NSLock()
  
  public init(state: State, mutations: MutationsType, actions: ActionsType) {
    self.nonatomicState = state
    self.mutations = mutations
    self.actions = actions
  }
  
  public func dispatch<ReturnType>(_ makeAction: (ActionsType) -> ActionsType.Action<ReturnType>) -> ReturnType {
    let context = DispatchContext<State, MutationsType, ActionsType>.init(store: self)
    let action = makeAction(actions)
    let result = action.action(context)
    return result
  }
  
  public func commit(_ makeMutation: (MutationsType) -> MutationsType.Mutation) {
    let mutation = makeMutation(mutations)
    lock.lock()
    mutation.mutate(&nonatomicState)
    lock.unlock()
  }
}


public final class ModularStore<State, MutationsType, ActionsType: Actions>: StoreBase where
  MutationsType.State == State,
  ActionsType.State == State,
  ActionsType.MutationsType == MutationsType
{
  
  init<SourceState, MutationsType, ActionsType: Actions>(
    store: Store<SourceState, MutationsType, ActionsType>
    ) where
    MutationsType.State == SourceState,
    ActionsType.State == SourceState,
    ActionsType.MutationsType == MutationsType
  {
    
  }
}
