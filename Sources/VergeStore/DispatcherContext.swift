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

/// A context object created from an action.
public final class DispatcherContext<Dispatcher: DispatcherType> {
  
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

extension DispatcherContext {
      
  /// Send activity
  /// - Parameter activity:
  public func send(_ activity: Dispatcher.Activity) {
    dispatcher.target._send(activity: activity)
  }
  
  /// Run Mutation
  /// - Parameter get: returns Mutation
  public func commit<Mutation: MutationType>(_ get: (Dispatcher) -> Mutation) -> Mutation.Result where Mutation.State == State {
    dispatcher.commit(get)
  }
  
  /// Run Mutation that created inline
  public func commitInline<Result>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ mutate: @escaping (inout State) -> Result) -> Result {
    dispatcher.commit { _ in
      Dispatcher.Mutation<Result>.init("inline_" + name, file, function, line, mutate: mutate)
    }
  }
  
  /// Run Action
  @discardableResult
  public func dispatch<Action: ActionType>(_ get: (Dispatcher) -> Action) -> Action.Result where Action.Dispatcher == Dispatcher {
    let action = get(dispatcher)
    let context = DispatcherContext<Dispatcher>.init(
      dispatcher: dispatcher,
      action: action,
      parent: self
    )
    return action.run(context: context)
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
