
import Foundation
import ObjectiveC

@_exported import RxFuture
@_exported import RxSwift
@_exported import RxCocoa

public enum VergeInternalError : Error {
  case vergeObjectWasDeallocated
}

public enum NoActivity {}
public struct NoState {}

public protocol VergeLogging : MutableStorageLogging {

  func didEmit(activity: Any, file: StaticString, function: StaticString, line: UInt, on verge: AnyVergeType)
  func willDispatch(name: String, description: String, file: StaticString, function: StaticString, line: UInt, on verge: AnyVergeType)
  func willMutate(name: String, description: String, file: StaticString, function: StaticString, line: UInt, on verge: AnyVergeType)
  func didMutate(name: String, description: String, file: StaticString, function: StaticString, line: UInt, on verge: AnyVergeType)
}

extension VergeLogging {
  static func empty() -> EmptyVergeLogger {
    return .init()
  }
}

public struct EmptyVergeLogger : VergeLogging {

  public init() {}

  public func didChange(root: Any) {}
  public func didReplace(root: Any) {}
  public func didEmit(activity: Any, file: StaticString, function: StaticString, line: UInt, on: AnyVergeType) {}
  public func willDispatch(name: String, description: String, file: StaticString, function: StaticString, line: UInt, on verge: AnyVergeType) {}
  public func willMutate(name: String, description: String, file: StaticString, function: StaticString, line: UInt, on verge: AnyVergeType) {}
  public func didMutate(name: String, description: String, file: StaticString, function: StaticString, line: UInt, on verge: AnyVergeType) {}
}

public protocol AnyVergeType : class {

}

/// The protocol is core of Cycler
public protocol VergeType : AnyVergeType {
  associatedtype State
  associatedtype Activity  
  var activity: Emitter<Activity> { get }
  var state: Storage<State> { get }
}

public protocol ModularVergeType : VergeType {
  associatedtype Parent : VergeType
}

private var _associated: Void?
private var _modularAssociated: Void?

@available(*, deprecated)
public final class DeinitBox {

  private let onDeinit: () -> Void

  init<T>(_ value: T, _ onDeinit: @escaping (T) -> Void) {
    self.onDeinit = {
      onDeinit(value)
    }
  }

  deinit {
    onDeinit()
  }
}

extension VergeType {

  private var associated: VergeAssociated<Activity> {
    if let associated = objc_getAssociatedObject(self, &_associated) as? VergeAssociated<Activity> {
      return associated
    } else {
      let associated = VergeAssociated<Activity>()
      objc_setAssociatedObject(self, &_associated, associated, .OBJC_ASSOCIATION_RETAIN)
      return associated
    }
  }
  
  private var logger: VergeLogging {
    return associated.logger ?? EmptyVergeLogger.init()
  }

  public func set(logger: VergeLogging) {
    lock.lock(); defer { lock.unlock() }
    associated.logger = logger
    state.mutableStateStorage.loggers = [logger]
  }

  public var activity: Emitter<Activity> {
    return associated.activity
  }

  private var lock: NSRecursiveLock {
    return associated.lock
  }

  /// Commit
  ///
  /// - Parameters:
  ///   - name:
  ///   - description:
  ///   - file:
  ///   - function:
  ///   - line:
  ///   - mutate:
  /// - Throws: 
  public func commit(
    _ name: String = "",
    _ description: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ mutate: (inout State) throws -> Void
    ) rethrows {

    defer {
      logger.didMutate(name: name, description: description, file: file, function: function, line: line, on: self)
    }

    logger.willMutate(name: name, description: description, file: file, function: function, line: line, on: self)

    try state.mutableStateStorage.update(mutate)
  }

  /// Commit
  ///
  /// - Parameters:
  ///   - name:
  ///   - description:
  ///   - file:
  ///   - function:
  ///   - line:
  ///   - newState:
  public func commit(
    _ name: String = "",
    _ description: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    replace newState: State
    ) {
    
    defer {
      logger.didMutate(name: name, description: description, file: file, function: function, line: line, on: self)
    }

    logger.willMutate(name: name, description: description, file: file, function: function, line: line, on: self)

    state.mutableStateStorage.replace(newState)
  }
  
  /// Dispatch
  ///
  /// - Parameters:
  ///   - name:
  ///   - description:
  ///   - file:
  ///   - function:
  ///   - line:
  ///   - action:
  /// - Returns:
  /// - Throws:
  @discardableResult
  public func dispatch<T>(
    _ name: String = "",
    _ description: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: (DispatchingContext<Self>) throws -> RxFuture<T>
    ) rethrows -> RxFuture<T> {
    
    logger.willDispatch(
      name: name,
      description: description,
      file: file,
      function: function,
      line: line,
      on: self
    )
    
    let context = DispatchingContext.init(
      actionName: name,
      source: self
    )
    
    let action = try action(context)
    
    return action

  }
  
  @discardableResult
  public func dispatchAsync<T>(
    _ name: String = "",
    _ description: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: (DispatchingContext<Self>) throws -> RxFuture<T>
    ) rethrows -> RxFuture<T> {
    
    return try dispatch(name, description, file, function, line, action)
  }
  
  public func dispatch(
    _ name: String = "",
    _ description: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: (DispatchingContext<Self>) throws -> Void
    ) rethrows {
    
    try dispatch(name, description, file, function, line) { (c) -> RxFuture<Void> in
        try action(c)
        return RxFuture<Void>.succeed(())
    }
    
  }

  /// Add modular Cycler
  ///
  /// - Parameters:
  ///   - module: CyclerType
  ///   - retainParent: Indicates retain parent
  public func add<M: ModularVergeType>(module: M, retainParent: Bool = false) where M.Parent == Self {
    if retainParent {
      module.modularAssociated.retainedParent = self
    } else {
      module.modularAssociated.parent = self
    }
  }

  fileprivate func emit(
    _ activity: Activity,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
    ) {

    self.activity.makeEmitter().accept(activity)
    logger.didEmit(activity: activity, file: file, function: function, line: line, on: self)
  }
}

extension ModularVergeType {

  fileprivate var modularAssociated: ModularVergeAssociated<Parent> {
    if let associated = objc_getAssociatedObject(self, &_modularAssociated) as? ModularVergeAssociated<Parent> {
      return associated
    } else {
      let associated = ModularVergeAssociated<Parent>()
      objc_setAssociatedObject(self, &_modularAssociated, associated, .OBJC_ASSOCIATION_RETAIN)
      return associated
    }
  }

  public func forward(_ c: (_ parent: Parent) -> Void) {
    guard let parent = modularAssociated.parent ?? modularAssociated.retainedParent else {
      assertionFailure("\(String(describing: self)) is not set parent. `should call set(parent: Parent)`")
      return
    }
    c(parent)
  }
}

public final class DispatchingContext<Verge : VergeType> {

  private weak var source: Verge?
  private let state: Storage<Verge.State>
  private let lock: NSLock = .init()
  private let actionName: String

  public var currentState: Verge.State {
    return state.value
  }

  init(actionName: String, source: Verge) {
    self.source = source
    self.state = source.state
    self.actionName = actionName
  }

  deinit {

  }

  public func commit(
    _ name: String = "",
    _ description: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ mutate: (inout Verge.State) throws -> Void
    ) rethrows {

    try source?.commit(name, description, file, function, line, mutate)
  }
  
  @discardableResult
  public func dispatch<U>(
    _ name: String = "",
    _ description: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: (DispatchingContext<Verge>) throws -> RxFuture<U>
    ) rethrows -> RxFuture<U> {
    
    return try source?.dispatch(name, description, file, function, line, action) ?? Single<U>.error(VergeInternalError.vergeObjectWasDeallocated).start()
    
  }
  
  public func dispatch(
    _ name: String = "",
    _ description: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: (DispatchingContext<Verge>) throws -> Void
    ) rethrows {
    
    try source?.dispatch(name, description, file, function, line, action)
    
  }
  
  @discardableResult
  public func dispatchAsync<U>(
    _ name: String = "",
    _ description: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: (DispatchingContext<Verge>) throws -> RxFuture<U>
    ) rethrows -> RxFuture<U> {
    
    return try source?.dispatch(name, description, file, function, line, action) ?? Single<U>.error(VergeInternalError.vergeObjectWasDeallocated).start()
    
  }

  public func emit(
    _ activity: Verge.Activity,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
    ) {
    source?.emit(activity, file: file, function: function, line: line)
  }

}

final class VergeAssociated<Activity> {

  let lock: NSRecursiveLock = .init()

  var logger: VergeLogging?

  lazy var activity: Emitter<Activity> = .init()

  init() {

  }
}

final class ModularVergeAssociated<Parent : VergeType> {

  weak var parent: Parent?

  var retainedParent: Parent?

  init() {

  }
}
