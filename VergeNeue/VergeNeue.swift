import Foundation

public struct MutationMetadata {
  
  public let name: String
  public let file: StaticString
  public let function: StaticString
  public let line: UInt
  
}

public struct ActionMetadata {
  
  public let name: String
  public let file: StaticString
  public let function: StaticString
  public let line: UInt
  
}

public struct _Mutation<State> {
  
  let mutate: (inout State) -> Void
  
  public let metadata: MutationMetadata
  
  public init(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    mutate: @escaping (inout State) -> Void
  ) {
    self.mutate = mutate
    self.metadata = .init(name: name, file: file, function: function, line: line)
  }
}

public struct _Action<Reducer: ModularReducerType, ReturnType> {
  
  let action: (DispatchContext<Reducer>) -> ReturnType
  
  public let metadata: ActionMetadata
  
  public init(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    action: @escaping (DispatchContext<Reducer>) -> ReturnType) {
    self.action = action
    self.metadata = .init(name: name, file: file, function: function, line: line)

  }
}

public protocol ModularReducerType {
  associatedtype TargetState
  
  typealias Mutation = _Mutation<TargetState>
  typealias Action<ReturnType> = _Action<Self, ReturnType>
  
  typealias StoreType = Store<Self>
  typealias ScopedStoreType = ScopedStore<ParentReducer, Self>
  typealias DispatchContext = VergeNeue.DispatchContext<Self>
    
  associatedtype ParentReducer: ModularReducerType
  func parentChanged(newState: ParentReducer.TargetState)
}

extension Never: ModularReducerType {
  public typealias TargetState = Never
  public typealias ParentReducer = Never
}

extension ModularReducerType where ParentReducer == Never {
  public func parentChanged(newState: ParentReducer.TargetState) {}
}

public protocol ReducerType: ModularReducerType where ParentReducer == Never {
    
}

public final class DispatchContext<Reducer: ModularReducerType> {
  
  private let store: StoreBase<Reducer>
  
  public var state: Reducer.TargetState {
    return store.state
  }
  
  init(store: StoreBase<Reducer>) {
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

