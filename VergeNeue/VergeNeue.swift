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
}

public final class DispatchContext<State, Reducer: ReducerType> where Reducer.TargetState == State {
  
  private let store: StoreBase<State, Reducer>
  
  init(store: StoreBase<State, Reducer>) {
    self.store = store
  }
  
  public func dispatch<ReturnType>(_ makeAction: (Reducer) -> Reducer.Action<ReturnType>) -> ReturnType {
    store.dispatch(makeAction)
  }
  
  public func dispatch(_ makeMutation: (Reducer) -> Reducer.Mutation) {
    store.dispatch(makeMutation)
  }
}

struct StorageSubscribeToken : Hashable {
  private let identifier = UUID().uuidString
}

final class Storage<Value> {
  
  private var subscribers: [StorageSubscribeToken : (Value) -> Void] = [:]
  
  var value: Value {
    lock.lock()
    defer {
      lock.unlock()
    }
    return nonatomicValue
  }
  
  private var nonatomicValue: Value
  
  private let lock = NSLock()
  
  init(_ value: Value) {
    self.nonatomicValue = value
  }
  
  func update(_ update: (inout Value) throws -> Void) rethrows {
    lock.lock()
    do {
      try update(&nonatomicValue)
    } catch {
      lock.unlock()
      throw error
    }
    lock.unlock()
    notify(value: nonatomicValue)
  }
  
  
  @discardableResult
  func add(subscriber: @escaping (Value) -> Void) -> StorageSubscribeToken {
    lock.lock(); defer { lock.unlock() }
    let token = StorageSubscribeToken()
    subscribers[token] = subscriber
    return token
  }
  
  func remove(subscriber: StorageSubscribeToken) {
    lock.lock(); defer { lock.unlock() }
    subscribers.removeValue(forKey: subscriber)
  }
  
  @inline(__always)
  fileprivate func notify(value: Value) {
    lock.lock()
    let subscribers: [StorageSubscribeToken : (Value) -> Void] = self.subscribers
    lock.unlock()
    subscribers.forEach { $0.value(value) }
  }
  
}

public struct StoreKey<State, Reducer: ReducerType> : Hashable where Reducer.TargetState == State {
  
  public let rawKey: String
  
  public init(additionalKey: String = "") {
    //    let baseKey = "\(String(reflecting: State.self)):\(String(reflecting: Operations.self))"
    let baseKey = "\(String(reflecting: StoreKey<State, Reducer>.self))"
    let key = baseKey + additionalKey
    self.rawKey = key
  }
  
  public init(from store: StoreBase<State, Reducer>, additionalKey: String = "") {
    self = StoreKey.init(additionalKey: additionalKey)
  }
  
  public init<Store: StoreType>(from store: Store, additionalKey: String = "") {
    self = StoreKey.init(additionalKey: additionalKey)
  }
}

public protocol StoreType where Reducer.TargetState == State {
  associatedtype State
  associatedtype Reducer: ReducerType
  
  func dispatch<ReturnType>(_ makeAction: (Reducer) -> Reducer.Action<ReturnType>) -> ReturnType
  func dispatch(_ makeMutation: (Reducer) -> Reducer.Mutation)
}

public struct RegistrationToken {
  
  private let _unregister: () -> Void
  
  init(_ unregister: @escaping () -> Void) {
    self._unregister = unregister
  }
  
  public func unregister() {
    self._unregister()
  }
}

public class StoreBase<State, Reducer: ReducerType>: StoreType where Reducer.TargetState == State {
  
  public func dispatch<ReturnType>(_ makeAction: (Reducer) -> _Action<Reducer.TargetState, Reducer, ReturnType>) -> ReturnType {
    fatalError()
  }
  
  public func dispatch(_ makeMutation: (Reducer) -> _Mutation<Reducer.TargetState>) {
    fatalError()
  }
  
  private var stores: [String : Any] = [:]
  private let lock = NSLock()
  
  private var registrationToken: RegistrationToken?
  
  func register<S, O: ReducerType>(store: StoreBase<S, O>, for key: String) -> RegistrationToken where O.TargetState == S {
    
    let key = StoreKey<S, O>.init(from: store).rawKey
    lock.lock()
    stores[key] = store
    
    let token = RegistrationToken { [weak self] in
      guard let self = self else { return }
      self.lock.lock()
      self.stores.removeValue(forKey: key)
      self.lock.unlock()
    }
    
    store.registrationToken = token
    lock.unlock()
    
    return token
  }
  
}

public final class Store<State, Reducer: ReducerType>: StoreBase<State, Reducer> where Reducer.TargetState == State {
  
  public var state: State {
    storage.value
  }
  
  let storage: Storage<State>
  
  private let operations: Reducer
  
  private let lock = NSLock()
  
  public init(
    state: State,
    operations: Reducer
  ) {
    self.storage = .init(state)
    self.operations = operations
  }
  
  public override func dispatch<ReturnType>(_ makeAction: (Reducer) -> Reducer.Action<ReturnType>) -> ReturnType {
    let context = DispatchContext<State, Reducer>.init(store: self)
    let action = makeAction(operations)
    let result = action.action(context)
    return result
  }
  
  public override func dispatch(_ makeMutation: (Reducer) -> Reducer.Mutation) {
    let mutation = makeMutation(operations)
    storage.update { (state) in
      mutation.mutate(&state)
    }
  }
  
  public func makeScoped<ScopedState, ScopedOperations: ReducerType>(
    scope: WritableKeyPath<State, ScopedState>,
    operations: ScopedOperations
  ) -> ScopedStore<State, ScopedState, ScopedOperations> where ScopedOperations.TargetState == ScopedState {
    
    let scopedStore = ScopedStore<State, ScopedState, ScopedOperations>(
      store: self,
      scopeSelector: scope,
      operations: operations
    )
    
    return scopedStore
  }
  
}

public final class ScopedStore<SourceState, State, Reducer: ReducerType>: StoreBase<State, Reducer> where Reducer.TargetState == State {
  
  public var state: State {
    storage.value[keyPath: scopeSelector]
  }
  
  private let operations: Reducer
  let storage: Storage<SourceState>
  private let scopeSelector: WritableKeyPath<SourceState, State>
  
  init<SourceOperations: ReducerType>(
    store: Store<SourceState, SourceOperations>,
    scopeSelector: WritableKeyPath<SourceState, State>,
    operations: Reducer
  ) {
    
    self.storage = store.storage
    self.operations = operations
    self.scopeSelector = scopeSelector
    
  }
  
  public override func dispatch<ReturnType>(_ makeAction: (Reducer) -> Reducer.Action<ReturnType>) -> ReturnType {
    let context = DispatchContext<State, Reducer>.init(store: self)
    let action = makeAction(operations)
    let result = action.action(context)
    return result
  }
  
  public override func dispatch(_ makeMutation: (Reducer) -> Reducer.Mutation) {
    let mutation = makeMutation(operations)
    storage.update { (sourceState) in
      mutation.mutate(&sourceState[keyPath: scopeSelector])
    }
  }
}

#if canImport(Combine)
import Combine

private var _associated: Void?

@available(iOS 13.0, *)
extension Storage: ObservableObject {
  
  public var objectWillChange: ObservableObjectPublisher {
    if let associated = objc_getAssociatedObject(self, &_associated) as? ObservableObjectPublisher {
      return associated
    } else {
      let associated = ObservableObjectPublisher()
      objc_setAssociatedObject(self, &_associated, associated, .OBJC_ASSOCIATION_RETAIN)
      
      add { _ in
        associated.send()
      }
      
      return associated
    }
  }
}

@available(iOS 13.0, *)
extension Store: ObservableObject {
  
  public var objectWillChange: ObservableObjectPublisher {
    storage.objectWillChange
  }
}

@available(iOS 13.0, *)
extension ScopedStore: ObservableObject {
  
  public var objectWillChange: ObservableObjectPublisher {
    storage.objectWillChange
  }
}

#endif
