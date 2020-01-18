//
// Copyright (c) 2020 muukii
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

/// A container object to create Mutation with scope keypath
public struct StateScope<State: StateType, Target> {
  
  public let keyPath: WritableKeyPath<State, Target>
  
  public init(keyPath: WritableKeyPath<State, Target>) {
    self.keyPath = keyPath
  }
        
}

extension DispatcherContext {
  
  /// Get state that scoped with StateScope.keyPath
  /// - Parameter scope: StateScope object
  public func scopedState<Target>(_ scope: StateScope<Dispatcher.State, Target>) -> Target {
    state[keyPath: scope.keyPath]
  }
}

extension StateScope {
  
  public func mutation<Result>(
    _ name: StaticString = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    inlineMutation: @escaping (inout Target) -> Result
  ) -> AnyMutation<State, Result> {
            
    .init(name.description, file, function, line) { [keyPath = keyPath] (state: inout State) in
      state.update(target: keyPath, update: inlineMutation)
    }
    
  }
  
  public func tryMutation<Result>(
    _ name: StaticString = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    inlineMutation: @escaping (inout Target) throws -> Result
  ) -> TryAnyMutation<State, Result> {
    
    .init(name.description, file, function, line) { [keyPath = keyPath] (state: inout State) in
      try state.update(target: keyPath, update: inlineMutation)
    }
    
  }
  
}
