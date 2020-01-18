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
    
  associatedtype State: StateType
  associatedtype Activity
  typealias Mutation<Return> = AnyMutation<Self, Return>
  typealias TryMutation<Return> = TryAnyMutation<Self, Return>
  typealias Action<Return> = AnyAction<Self, Return>
  typealias TryAction<Return> = TryAnyAction<Self, Return>
  var target: StoreBase<State, Activity> { get }
  
}

extension DispatcherType {
      
  /// Run Mutation
  /// - Parameter get: returns Mutation
  public func commit<Mutation: MutationType>(_ get: (Self) -> Mutation) -> Mutation.Result where Mutation.State == State {
    let mutation = get(self)
    return target._receive(
      context: Optional<DispatcherContext<Self>>.none,
      mutation: mutation
    )
  }
  
  /// Run Mutation
  /// - Parameter get: returns Mutation
  public func commit<TryMutation: TryMutationType>(_ get: (Self) -> TryMutation) throws -> TryMutation.Result where TryMutation.State == State {
    let mutation = get(self)
    return try target._receive(
      context: Optional<DispatcherContext<Self>>.none,
      mutation: mutation
    )
  }
      
  ///
  /// - Parameter get: Return Action object
  @discardableResult
  public func dispatch<Action: ActionType>(_ get: (Self) -> Action) -> Action.Result where Action.Dispatcher == Self {
    dispatch(get(self))
  }
  
  ///
  /// - Parameter get: Return Action object
  @discardableResult
  public func dispatch<TryAction: TryActionType>(_ get: (Self) -> TryAction) throws -> TryAction.Result where TryAction.Dispatcher == Self {
    try dispatch(get(self))
  }
  
  @discardableResult
  @inline(__always)
  public func dispatch<Action: ActionType>(_ action: Action) -> Action.Result where Action.Dispatcher == Self {
    let context = DispatcherContext<Self>.init(
      dispatcher: self,
      action: action,
      parent: nil
    )
    return action.run(context: context)
  }
  
  ///
  /// - Parameter get: Return Action object
  @discardableResult
  @inline(__always)
  public func dispatch<TryAction: TryActionType>(_ action: TryAction) throws -> TryAction.Result where TryAction.Dispatcher == Self {
    let context = DispatcherContext<Self>.init(
      dispatcher: self,
      action: action,
      parent: nil
    )
    return try action.run(context: context)
  }
  
  @discardableResult
  public func dispatchInline<Result>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: @escaping ((DispatcherContext<Self>) -> Result)
  ) -> Result {
    
    dispatch { _ in
      Action(name, file, function, line, action)
    }
    
  }
  
  @discardableResult
  public func dispatchInline<Result>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: @escaping ((DispatcherContext<Self>) throws -> Result)
  ) throws -> Result {
    
    try dispatch { _ in
      TryAction(name, file, function, line, action)
    }
    
  }

}

// MARK: - Xcode Support
extension DispatcherType {
  
  /// Dummy Method to work Xcode code completion
//  @available(*, unavailable)
  public func commit(_ get: (Self) -> Never) -> Never { fatalError() }
  
  /// Dummy Method to work Xcode code completion
//  @available(*, unavailable)
  public func dispatch(_ get: (Self) -> Never) -> Never { fatalError() }
}
