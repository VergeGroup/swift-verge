//
// Copyright (c) 2019 muukii
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

public protocol DispacherContextType {
  associatedtype Dispatcher: DispatcherType
  var dispatcher: Dispatcher { get }
}

/// A context object created from an action.
public class DispatcherContext<Dispatcher: DispatcherType>: DispacherContextType {

  public typealias State = Dispatcher.State
    
  /// Target dispatcher
  public let dispatcher: Dispatcher
  
  /// From Action
  public let action: ActionBaseType
  
  /// Parent context.
  /// non-nil means this context's action has been dispatched another context
  private let parent: DispatcherContext<Dispatcher>?
  
  /// Returns current state from target store
  public var state: State {
    return dispatcher.target.state
  }
  
  init(
    dispatcher: Dispatcher,
    action: ActionBaseType,
    parent: DispatcherContext<Dispatcher>?
  ) {
    self.dispatcher = dispatcher
    self.action = action
    self.parent = parent
  }
     
}

/*
public final class ScopedDispatcherContext<Dispatcher: DispatcherType, Scope>: DispatcherContext<Dispatcher> {
  
  public let scope: WritableKeyPath<Dispatcher.State, Scope>
  
  /// Returns current state from target store
  public var scopedState: Scope {
    return dispatcher.target.state[keyPath: scope]
  }
  
  init(
    scope: WritableKeyPath<Dispatcher.State, Scope>,
    dispatcher: Dispatcher,
    action: ActionBaseType,
    parent: DispatcherContext<Dispatcher>?
  ) {
    self.scope = scope
    super.init(dispatcher: dispatcher, action: action, parent: parent)
  }
  
}
 */

extension DispatcherContext {
      
  /// Send activity
  /// - Parameter activity:
  public func send(_ activity: Dispatcher.Activity) {
    dispatcher.target._send(activity: activity)
  }
  
  /// Run Mutation
  /// - Parameter mutation: returns Mutation
  public func commit<Mutation: MutationType>(mutation: (Dispatcher) -> Mutation) -> Mutation.Result where Mutation.State == State {
    dispatcher.target._receive(context: self, mutation: mutation(dispatcher))
  }
  
  /// Run Mutation
  /// - Parameter mutation: returns Mutation
  public func commit<TryMutation: TryMutationType>(mutation: (Dispatcher) -> TryMutation) throws -> TryMutation.Result where TryMutation.State == State {
    try dispatcher.target._receive(context: self, mutation: mutation(dispatcher))
  }
  
  /// Run Mutation that created inline
  public func commitInline<Result>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    mutate: @escaping (inout State) -> Result
  ) -> Result {
    commit { _ in
      Dispatcher.Mutation<Result>.init("inline_" + name, file, function, line, mutate: mutate)
    }
  }
  
  /// Run Mutation that created inline
  public func commitInline<Result>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    mutate: @escaping (inout State) throws -> Result
  ) throws -> Result {
    try commit { _ in
      Dispatcher.TryMutation<Result>.init("inline_" + name, file, function, line, mutate: mutate)
    }
  }
  
  /// Run Action
  @discardableResult
  public func dispatch<Action: ActionType>(action: (Dispatcher) -> Action) -> Action.Result where Action.Dispatcher == Dispatcher {
    dispatch(action: action(dispatcher))
  }
  
  /// Run Action
  @discardableResult
  public func dispatch<TryAction: TryActionType>(action: (Dispatcher) -> TryAction) throws -> TryAction.Result where TryAction.Dispatcher == Dispatcher {
    try dispatch(action: action(dispatcher))
  }
  
  /// Run Action
  @discardableResult
  public func dispatch<Action: ActionType>(action: Action) -> Action.Result where Action.Dispatcher == Dispatcher {
    let context = DispatcherContext<Dispatcher>.init(
      dispatcher: dispatcher,
      action: action,
      parent: self
    )
    return action.run(context: context)
  }
  
  /// Run Action
  @discardableResult
  public func dispatch<TryAction: TryActionType>(action: TryAction) throws -> TryAction.Result where TryAction.Dispatcher == Dispatcher {
    let context = DispatcherContext<Dispatcher>.init(
      dispatcher: dispatcher,
      action: action,
      parent: self
    )
    return try action.run(context: context)
  }
  
}

// MARK: - Xcode Support
extension DispatcherContext {
  
  /// Dummy Method to work Xcode code completion
//  @available(*, unavailable)
  public func commit(_ get: (Dispatcher) -> Never) -> Never { fatalError() }
  
  /// Dummy Method to work Xcode code completion
//  @available(*, unavailable)
  public func dispatch(_ get: (Dispatcher) -> Never) -> Never { fatalError() }
}

extension DispatcherContext: CustomReflectable {
  
  public var customMirror: Mirror {
    Mirror(
      self,
      children: [
        "action": action,
        "parent" : parent as Any
      ],
      displayStyle: .struct
    )
  }
}
