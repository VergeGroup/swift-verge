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
    
  associatedtype WrappedStore: StoreType
  associatedtype Scope = WrappedStore.State
    
  var store: WrappedStore { get }
  var scope: WritableKeyPath<WrappedStore.State, Scope> { get }
  
}

extension DispatcherType where Scope == WrappedStore.State {
  
   public var scope: WritableKeyPath<WrappedStore.State, WrappedStore.State> { \WrappedStore.State.self }
  
}

extension DispatcherType {
      
  public typealias Context = ContextualDispatcher<Self, Scope>
  
  /// Send activity
  /// - Parameter activity:
  public func send(_ activity: WrappedStore.Activity) {
    store.asStore()._send(activity: activity)
  }
      
  /// Run Mutation that created inline
  ///
  /// Throwable
  public func commit<Result>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    mutation: (inout Scope) throws -> Result
  ) rethrows -> Result {
    
    let meta = MutationMetadata(
      name: name,
      file: file.description,
      function: function.description,
      line: line
    )
    
    return try store.asStore()._receive(
      metadata: meta,
      mutation: { state in
        try mutation(&state[keyPath: scope])
    })
  }
      
  /// Run Mutation that created inline
  ///
  /// Throwable
  public func commit<Result, NewScope>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    scope: WritableKeyPath<WrappedStore.State, NewScope>,
    mutation: (inout NewScope) throws -> Result
  ) rethrows -> Result {
    
    let meta = MutationMetadata(
      name: name,
      file: file.description,
      function: function.description,
      line: line
    )
    
    return try store.asStore()._receive(
      metadata: meta,
      mutation: { state in
        try mutation(&state[keyPath: scope])
    }
    )
  }
    
}
