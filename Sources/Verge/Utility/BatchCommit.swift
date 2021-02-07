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

/**
 A context to batch multiple mutations
 */
public struct BatchCommitContext<State, Scope> {

  typealias Mutation = (MutationTrace, (inout InoutRef<State>) -> Void)

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
    mutation: @escaping (inout InoutRef<Scope>) -> Void
  ) {

    let trace = MutationTrace(
      name: name,
      file: file,
      function: function,
      line: line
    )

    mutations.append((trace, { [scope] state in
      state.map(keyPath: scope) { (ref) -> Void in
        mutation(&ref)
      }
    }))

  }

  /// Registers Mutation that created inline
  public mutating func commit<NewScope>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    scope: WritableKeyPath<State, NewScope>,
    mutation: @escaping (inout InoutRef<NewScope>) -> Void
  ) {

    let trace = MutationTrace(
      name: name,
      file: file,
      function: function,
      line: line
    )

    mutations.append((trace, { state in
      state.map(keyPath: scope) { (ref: inout InoutRef<NewScope>) -> Void in
        mutation(&ref)
      }
    }))

  }

  /// Registers Mutation that created inline
  public mutating func commit<NewScope>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    scope: WritableKeyPath<State, NewScope?>,
    mutation: @escaping (inout InoutRef<NewScope>?) -> Void
  ) {

    let trace = MutationTrace(
      name: name,
      file: file,
      function: function,
      line: line
    )

    mutations.append((trace, { state in
      state.map(keyPath: scope) { (ref: inout InoutRef<NewScope>?) -> Void in
        mutation(&ref)
      }
    }))

  }


}

extension DispatcherType {

  /**
   Performs multiple commits at once.
   From calling this method a transaction starts, register mutation into `BatchUpdate` instance.
   If it has no mutations, batch updating won't be executed.
   */
  @available(*, deprecated, message: "Use commit in favor of https://github.com/VergeGroup/Verge/pull/180")
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
