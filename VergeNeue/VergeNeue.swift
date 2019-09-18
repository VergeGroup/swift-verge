import Foundation

public struct CodeLocation {
  
  public let file: StaticString
  public let function: StaticString
  public let line: UInt
  
}

public struct _Mutation<State> {
  
  let mutate: (inout State) -> Void
  
  public let codeLocation: CodeLocation
  
  public init(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    mutate: @escaping (inout State) -> Void
  ) {
    self.mutate = mutate
    self.codeLocation = .init(file: file, function: function, line: line)
  }
}

public struct _Action<Reducer: ModularReducerType, ReturnType> {
  
  let action: (DispatchContext<Reducer>) -> ReturnType
  
  public let codeLocation: CodeLocation
  
  public init(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    action: @escaping (DispatchContext<Reducer>
    ) -> ReturnType) {
    self.action = action
    self.codeLocation = .init(file: file, function: function, line: line)

  }
}

public protocol ModularReducerType {
  associatedtype TargetState
  
  typealias Mutation = _Mutation<TargetState>
  typealias Action<ReturnType> = _Action<Self, ReturnType>
  
  typealias StoreType = Store<Self>
  typealias ScopedStoreType<RootReducer: ModularReducerType> = ScopedStore<RootReducer, Self>
  typealias DispatchContext = VergeNeue.DispatchContext<Self>
    
  associatedtype ParentState
  func parentChanged(newState: ParentState)
}

extension ModularReducerType where ParentState == Void {
  public func parentChanged(newState: ParentState) {}
}

public protocol ReducerType: ModularReducerType where ParentState == Void {
    
}

public final class DispatchContext<Reducer: ModularReducerType> {
  
  private let store: StoreBase<Reducer>
  
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

