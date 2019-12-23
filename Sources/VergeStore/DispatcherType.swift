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

public protocol DispatcherType {
    
  associatedtype State
  associatedtype Activity
  typealias Mutation<Return> = AnyMutation<Self, Return>
  typealias Action<Return> = AnyAction<Self, Return>
  var dispatchTarget: StoreBase<State, Activity> { get }
  
}

extension DispatcherType {
  
  /// Dummy Method to work Xcode code completion
  public func accept(_ get: (Self) -> Never) -> Never {
    fatalError()
  }
  
  ///
  /// - Parameter get: Return Mutation Object
  public func accept<Mutation: MutationType>(_ get: (Self) -> Mutation) -> Mutation.Result where Mutation.State == State {
    let mutation = get(self)
    return dispatchTarget._receive(
      context: Optional<DispatcherContext<Self>>.none,
      mutation: mutation
    )
  }
    
  ///
  /// - Parameter get: Return Action object
  @discardableResult
  public func accept<Action: ActionType>(_ get: (Self) -> Action) -> Action.Result where Action.Dispatcher == Self {
    let action = get(self)
    let context = DispatcherContext<Self>.init(
      dispatcher: self,
      action: action,
      parent: nil
    )
    return action.run(context: context)
  }

}

public protocol ScopedDispatching: DispatcherType where State : StateType {
  associatedtype Scoped
  
  static var scopedStateKeyPath: WritableKeyPath<State, Scoped> { get }
}
