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
  typealias Store = StoreBase<State>
  typealias Mutation = AnyMutation<Self>
  typealias Action<Return> = AnyAction<Self, Return>
  var dispatchTarget: Store { get }
  
}

extension DispatcherType {
  
  ///
  /// - Parameter get: Return Mutation Object
  public func accept(_ get: (Self) -> Mutation) {
    let mutation = get(self)
    dispatchTarget._receive(
      context: Optional<VergeStoreDispatcherContext<Self>>.none,
      mutation: mutation
    )
  }
    
  ///
  /// - Parameter get: Return Action object
  @discardableResult
  public func accept<Return>(_ get: (Self) -> Action<Return>) -> Return {
    let action = get(self)
    let context = VergeStoreDispatcherContext<Self>.init(
      dispatcher: self,
      metadata: action.metadata,
      parent: nil
    )
    return action._action(context)
  }

}

public protocol ScopedDispatching: DispatcherType where State : StateType {
  associatedtype Scoped
  
  static var scopedStateKeyPath: WritableKeyPath<State, Scoped> { get }
}
