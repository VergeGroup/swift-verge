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
  public let metadata: ActionMetadata
  private let parent: DispatcherContext<Dispatcher>?
  
  public var state: State {
    return dispatcher.dispatchTarget.state
  }
  
  init(
    dispatcher: Dispatcher,
    metadata: ActionMetadata,
    parent: DispatcherContext<Dispatcher>?
  ) {
    self.dispatcher = dispatcher
    self.metadata = metadata
    self.parent = parent
  }
     
}

extension DispatcherContext {
    
  /// Run Mutation
  /// - Parameter get: returns Mutation
  public func accept(_ get: (Dispatcher) -> Dispatcher.Mutation) {
    dispatcher.accept(get)
  }
  
  /// Run Action
  @discardableResult
  public func accept<Return>(_ get: (Dispatcher) -> Dispatcher.Action<Return>) -> Return {
    let action = get(dispatcher)
    let context = DispatcherContext<Dispatcher>.init(
      dispatcher: dispatcher,
      metadata: action.metadata,
      parent: self
    )
    return action._action(context)
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
        "metadata": metadata,
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
