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

/// For supports Xcode code completion
public protocol _ActionType {
  associatedtype Reducer: ModularReducerType
  associatedtype ReturnType
  func asAction() -> _Action<Reducer, ReturnType>
}

public struct _Action<Reducer: ModularReducerType, ReturnType>: _ActionType {
  
  let action: (StoreDispatchContext<Reducer>) -> ReturnType
  
  public let metadata: ActionMetadata
  
  public init(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    action: @escaping (StoreDispatchContext<Reducer>) -> ReturnType) {
    self.action = action
    self.metadata = .init(name: name, file: file, function: function, line: line)

  }
  
  public func asAction() -> _Action<Reducer, ReturnType> {
    return self
  }
}

public struct _ScopedAction<Reducer: ScopedReducerType, ReturnType> {
  
  let action: (ScopedDispatchContext<Reducer>) -> ReturnType
  
  public let metadata: ActionMetadata
  
  public init(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    action: @escaping (ScopedDispatchContext<Reducer>) -> ReturnType) {
    self.action = action
    self.metadata = .init(name: name, file: file, function: function, line: line)
    
  }
}

public final class StoreDispatchContext<Reducer: ModularReducerType> {
  
  private let store: Store<Reducer>
  
  public var state: Reducer.State {
    return store.state
  }
  
  init(store: Store<Reducer>) {
    self.store = store
  }
  
  @discardableResult
  public final func dispatch<Action: _ActionType>(_ makeAction: (Reducer) -> Action) -> Action.ReturnType where Action.Reducer == Reducer {
    store.dispatch(makeAction)
  }
    
  public func commit(_ makeMutation: (Reducer) -> Reducer.Mutation) {
    store.commit(makeMutation)
  }
}

public final class ScopedDispatchContext<Reducer: ScopedReducerType> {
  
  private let store: ScopedStore<Reducer>
  
  public var state: Reducer.TargetState {
    return store.state
  }
  
  init(store: ScopedStore<Reducer>) {
    self.store = store
  }
  
  @discardableResult
  public func dispatch<ReturnType>(_ makeAction: (Reducer) -> Reducer.ScopedAction<ReturnType>) -> ReturnType {
    store.dispatch(makeAction)
  }
  
  public func commit(_ makeMutation: (Reducer) -> Reducer.Mutation) {
    store.commit(makeMutation)
  }
}

