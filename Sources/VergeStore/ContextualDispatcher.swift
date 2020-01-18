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
public struct ContextualDispatcher<Dispatcher: DispatcherType>: DispacherContextType, DispatcherType {
  
  public var target: StoreBase<Dispatcher.State, Dispatcher.Activity> {
    dispatcher.target
  }
    
  public typealias Activity = Dispatcher.Activity
  
  public typealias State = Dispatcher.State
    
  /// Target dispatcher
  public let dispatcher: Dispatcher
  
  /// From Action
  public let actionMetadata: ActionMetadata
    
  /// Returns current state from target store
  public var state: State {
    return dispatcher.target.state
  }
  
  init(
    dispatcher: Dispatcher,
    actionMetadata: ActionMetadata
  ) {
    self.dispatcher = dispatcher
    self.actionMetadata = actionMetadata
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

extension ContextualDispatcher {
 
  public func redirect<Result>(_ redirect: (Dispatcher) throws -> Result) rethrows -> Result {
    return try redirect(dispatcher)
  }
}

extension ContextualDispatcher: CustomReflectable {
  
  public var customMirror: Mirror {
    Mirror(
      self,
      children: [
        "action": actionMetadata
      ],
      displayStyle: .struct
    )
  }
}
