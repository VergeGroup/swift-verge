
public protocol Dispatching {
  associatedtype State
  typealias Store = VergeDefaultStore<State>
  var targetStore: Store { get }
}

public protocol ScopedDispatching: Dispatching where State : StateType {
  associatedtype Scoped
  
  var selector: WritableKeyPath<State, Scoped> { get }
}

extension Dispatching {
  
  @discardableResult
  public func dispatch<ReturnType>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ inlineAction: (VergeStoreDispatcherContext<Self>) throws -> ReturnType
  ) rethrows -> ReturnType {
    
    let metadata = ActionMetadata(name: name, file: file, function: function, line: line)
    
    let context = VergeStoreDispatcherContext<Self>.init(dispatcher: self)
    let result = try inlineAction(context)
    targetStore.logger?.didDispatch(store: targetStore, state: targetStore.state, action: metadata, context: context)
    return result
    
  }
  
  public func commit(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ context: VergeStoreDispatcherContext<Self>? = nil,
    _ inlineMutation: (inout State) throws -> Void
  ) rethrows {
    
    let metadata = MutationMetadata(name: name, file: file, function: function, line: line)
    
    try targetStore.receive(
      context: context,
      metadata: metadata,
      mutation: inlineMutation
    )
    
  }
  
}

extension Dispatching where State : StateType {
  
  public func commit<Target>(
    _ target: WritableKeyPath<State, Target>,
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ context: VergeStoreDispatcherContext<Self>? = nil,
    _ inlineMutation: (inout Target) throws -> Void
  ) rethrows {
    
    let metadata = MutationMetadata(name: name, file: file, function: function, line: line)
    
    try targetStore.receive(
      context: context,
      metadata: metadata,
      mutation: { ( state: inout State) in
        try state.update(target: target, update: inlineMutation)
    })
    
  }
  
  public func commit<Target: _VergeStore_OptionalProtocol>(
    _ target: WritableKeyPath<State, Target>,
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ context: VergeStoreDispatcherContext<Self>? = nil,
    _ inlineMutation: (inout Target.Wrapped) throws -> Void
  ) rethrows {
    
    let metadata = MutationMetadata(name: name, file: file, function: function, line: line)
    
    try targetStore.receive(
      context: context,
      metadata: metadata,
      mutation: { ( state: inout State) in
        try state.update(target: target, update: inlineMutation)
    })
    
  }
  
}

open class Dispatcher<S>: Dispatching {
  
  public typealias State = S
  
  public typealias Context = VergeStoreDispatcherContext<Dispatcher<State>>
  
  public let targetStore: Store
  
  private var logger: VergeStoreLogger? {
    targetStore.logger
  }
  
  public init(target store: Store) {
    self.targetStore = store
    
    logger?.didCreateDispatcher(store: store, dispatcher: self)
  }
  
  deinit {
    logger?.didDestroyDispatcher(store: targetStore, dispatcher: self)
  }
  
}

public protocol _VergeStore_OptionalProtocol {
  associatedtype Wrapped
  var _vergestore_wrappedValue: Wrapped? { get set }
}

extension Optional: _VergeStore_OptionalProtocol {
  
  public var _vergestore_wrappedValue: Wrapped? {
    get {
      return self
    }
    mutating set {
      self = newValue
    }
  }
}

extension ScopedDispatching where State : StateType {
  
  public func commitScoped(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ context: VergeStoreDispatcherContext<Self>? = nil,
    _ inlineMutation: (inout Scoped) throws -> Void) rethrows {
        
    try self.commit(
      selector,
      name,
      file,
      function,
      line,
      context,
      inlineMutation
    )
    
  }
  
}

extension ScopedDispatching where State : StateType, Scoped : _VergeStore_OptionalProtocol {
  
  public func commitScopedIfPresent(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ context: VergeStoreDispatcherContext<Self>? = nil,
    _ inlineMutation: (inout Scoped.Wrapped) throws -> Void) rethrows {
    
    try self.commit(
      selector,
      name,
      file,
      function,
      line,
      context,
      inlineMutation
    )
    
  }
  
}
