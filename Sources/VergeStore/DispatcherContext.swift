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

public final class DispatcherContext<Dispatcher: DispatcherType> {
  
  public typealias State = Dispatcher.State
  
  public let dispatcher: Dispatcher
  public let action: ActionBaseType
  private let parent: DispatcherContext<Dispatcher>?
  
  public var state: State {
    return dispatcher.dispatchTarget.state
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
  
  /// Dummy Method to work Xcode code completion
  public func accept(_ get: (Dispatcher) -> Never) -> Never {
    fatalError()
  }
    
  /// Run Mutation
  /// - Parameter get: returns Mutation
  public func accept<Mutation: MutationType>(_ get: (Dispatcher) -> Mutation) -> Mutation.Result where Mutation.State == State {
    dispatcher.accept(get)
  }
  
  /// Run Action
  @discardableResult
  public func accept<Action: ActionType>(_ get: (Dispatcher) -> Action) -> Action.Result where Action.Dispatcher == Dispatcher {
    let action = get(dispatcher)
    let context = DispatcherContext<Dispatcher>.init(
      dispatcher: dispatcher,
      action: action,
      parent: self
    )
    return action.run(context: context)
  }
    
  /// Send activity
  /// - Parameter activity:
  public func send(_ activity: Dispatcher.Activity) {
    dispatcher.dispatchTarget._send(activity: activity)
  }
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

extension DispatcherContext where Dispatcher : ScopedDispatching {
  
  public var scopedState: Dispatcher.Scoped {
    state[keyPath: Dispatcher.scopedStateKeyPath]
  }
  
}
