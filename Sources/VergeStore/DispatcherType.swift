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
  var target: StoreBase<State, Activity> { get }
  
}

extension DispatcherType {
  
  /// Send activity
  /// - Parameter activity:
  public func send(_ activity: Activity) {
    target._send(activity: activity)
  }
      
  /// Run Mutation that created inline
  ///
  /// Throwable
  public func commit<Result>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    mutation: (inout State) throws -> Result
  ) rethrows -> Result {
    let meta = MutationMetadata(name: name, file: file, function: function, line: line)
    return try target._receive(
      context: self,
      metadata: meta,
      mutation: mutation
    )
  }
  
  /// Run Mutation that created inline
  ///
  /// Throwable
  public func commit<Scope, Result>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    scope: WritableKeyPath<State, Scope>,
    mutation: (inout Scope) throws -> Result
  ) rethrows -> Result {
    let meta = MutationMetadata(name: name, file: file, function: function, line: line)
    return try target._receive(
      context: self,
      metadata: meta,
      mutation: { state in
        try state.update(target: scope, update: mutation)
    }
    )
  }
      
  /// Run action that created inline
  @discardableResult
  public func dispatch<Result>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    action: ((ContextualDispatcher<Self>) throws -> Result)
  ) rethrows -> Result {
    
    let meta = ActionMetadata(name: name, file: file, function: function, line: line)
    
    let context = ContextualDispatcher<Self>.init(
      dispatcher: self,
      actionMetadata: meta
    )
    
    return try action(context)
        
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
