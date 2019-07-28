
import Combine

public protocol VergeSwiftUIType where Self : AnyObject {
  
  associatedtype State
  
  /// TODO: Workaround, cannot define `@Storage var state: State { get }`
  var storage: VergeSwiftUIStorage<State> { get }
}

extension VergeSwiftUIType {
  
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
    
    try storage.makeWritableContext().commit(mutate)
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
  public func dispatch<P: Publisher, T, E>(
    _ name: String = "",
    _ description: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: (DispatchingContext<Self>) throws -> P
    ) rethrows -> P where P.Output == T, P.Failure == E {
    
    let context = DispatchingContext.init(
      actionName: name,
      source: self
    )
    
    let action = try action(context)
    
    return action
  }
}

public final class DispatchingContext<Verge : VergeSwiftUIType> {
  
  private let target: Verge
  private let storage: VergeSwiftUIStorage<Verge.State>
  private let lock: NSLock = .init()
  private let actionName: String
  
  public var currentState: Verge.State {
    return storage.wrappedValue
  }
  
  init(actionName: String, source: Verge) {
    self.target = source
    self.storage = source.storage
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
    
    try target.commit(name, description, file, function, line, mutate)
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
  public func dispatch<P: Publisher, T, E>(
    _ name: String = "",
    _ description: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: (DispatchingContext<Verge>) throws -> P
    ) rethrows -> P where P.Output == T, P.Failure == E {
    
    return try target.dispatch(name, description, file, function, line, action)
  }
  
}


#if canImport(SwiftUI)
import SwiftUI

public extension VergeSwiftUIType where Self : BindableObject {
  var willChange: VergeSwiftUIStorage<State>.WillChangePublisher {
    return storage.willChange
  }
}

#endif
