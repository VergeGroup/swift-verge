
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
