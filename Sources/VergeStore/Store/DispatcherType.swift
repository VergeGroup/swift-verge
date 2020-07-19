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
  
  /// Send activity
  /// - Parameter activity:
  public func send(
    _ name: String = "",
    _ activity: WrappedStore.Activity,
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line
  ) {
    let trace = ActivityTrace(
      name: name,
      file: file.description,
      function: function.description,
      line: line
    )
    
    store.asStore()._send(activity: activity, trace: trace)
  }
        
  /// Send activity
  /// - Parameter activity:
  public func send(
    _ activity: WrappedStore.Activity,
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line
  ) {
    send("", activity, file, function, line)
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
    
    let trace = MutationTrace(
      name: name,
      file: file.description,
      function: function.description,
      line: line
    )
    
    return try store.asStore()._receive(
      mutation: { state in
        try mutation(&state[keyPath: scope])
    },
      trace: trace
    )
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
    
    let trace = MutationTrace(
      name: name,
      file: file.description,
      function: function.description,
      line: line
    )
    
    return try store.asStore()._receive(
      mutation: { state in
        try mutation(&state[keyPath: scope])
    },
      trace: trace
    )
  }
  
  public func detached<NewScope>(from newScope: WritableKeyPath<WrappedStore.State, NewScope>) -> DetachedDispatcher<WrappedStore.State, WrappedStore.Activity, NewScope> {
    .init(targetStore: store.asStore(), scope: newScope)
  }
  
  public func detached<NewScope>(by appendingScope: WritableKeyPath<Scope, NewScope>) -> DetachedDispatcher<WrappedStore.State, WrappedStore.Activity, NewScope> {
    .init(targetStore: store.asStore(), scope: self.scope.appending(path: appendingScope))
  }
    
}

/**
 A context to batch multiple mutations
 */
public struct BatchCommitContext<State, Scope> {

  typealias Mutation = (MutationTrace, (inout State) -> Void)

  private(set) var mutations: [Mutation] = []

  let scope: WritableKeyPath<State, Scope>

  init(scope: WritableKeyPath<State, Scope>) {
    self.scope = scope
  }

  /// Registers Mutation that created inline
  public mutating func commit(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    mutation: @escaping (inout Scope) -> Void
  ) {

    let trace = MutationTrace(
      name: name,
      file: file.description,
      function: function.description,
      line: line
    )

    mutations.append((trace, { [scope] state in
      mutation(&state[keyPath: scope])
    }))

  }

  /// Registers Mutation that created inline
  public mutating func commit<NewScope>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    scope: WritableKeyPath<State, NewScope>,
    mutation: @escaping (inout NewScope) -> Void
  ) {

    let trace = MutationTrace(
      name: name,
      file: file.description,
      function: function.description,
      line: line
    )

    mutations.append((trace, { state in
      mutation(&state[keyPath: scope])
    }))

  }

}

extension DispatcherType {

  /**
   Performs multiple commits at once.
   From calling this method a transaction starts, register mutation into `BatchUpdate` instance.
   If it has no mutations, batch updating won't be executed.
   */
  public func batchCommit(_ perform: (_ context: inout BatchCommitContext<WrappedStore.State, Scope>) -> Void) {

    var context = BatchCommitContext<WrappedStore.State, Scope>(scope: scope)

    perform(&context)

    guard !context.mutations.isEmpty else {
      return
    }

    commit("BatchUpdating", scope: \.self) { (state) -> Void in
      for mutation in context.mutations {
        mutation.1(&state)
      }
    }

  }

}
