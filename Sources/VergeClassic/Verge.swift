
import Foundation
import ObjectiveC

#if !COCOAPODS
import VergeCore
#endif

@_exported import RxSwift
@_exported import RxCocoa

public enum VergeInternalError : Error {
  case vergeObjectWasDeallocated
}

public enum NoActivity {}
public struct NoState {
  public init() {}
}

public protocol VergeLogging {

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

private var _associated: Void?

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

    try state.update(mutate)
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
    state.update {
      $0 = newState
    }
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
  public func dispatch<Return>(
    _ name: String = "",
    _ description: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: (DispatchingContext<Self>) throws -> Return
    ) rethrows -> Return {
    
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
    
    let returnValue = try action(context)
    
    return returnValue

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

public final class DispatchingContext<Verge : VergeType> {

  private let source: Verge
  private let state: Storage<Verge.State>
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

    try source.commit(name, description, file, function, line, mutate)
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
    replace newState: Verge.State
  ) {
           
    source.commit(name, description, file, function, line, replace: newState)
  }
  
  @discardableResult
  public func dispatch<Return>(
    _ name: String = "",
    _ description: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: (DispatchingContext<Verge>) throws -> Return
    ) rethrows -> Return {
    
    try source.dispatch(name, description, file, function, line, action)
    
  }
   
  public func emit(
    _ activity: Verge.Activity,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
    ) {
    source.emit(activity, file: file, function: function, line: line)
  }

}

final class VergeAssociated<Activity> {

  let lock: NSRecursiveLock = .init()

  var logger: VergeLogging?

  lazy var activity: Emitter<Activity> = .init()

  init() {

  }
}
