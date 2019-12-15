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

public struct AnyMutation<From: DispatcherType> {
  
  let _mutate: (inout From.State) -> Void
  
  public let metadata: MutationMetadata
  
  public init(
    _ name: StaticString = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    mutate: @escaping (inout From.State) -> Void
  ) {
    
    self.metadata = .init(name: name, file: file, function: function, line: line)
    self._mutate = mutate
  }
  
}

extension AnyMutation {
  
  public static func mutation(
    _ name: StaticString = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    inlineMutation: @escaping (inout From.State) -> Void
  ) -> Self {
    
    self.init(name, file, function, line, mutate: inlineMutation)
    
  }
  
}

extension AnyMutation where From.State : StateType {
  
  public static func mutation<Target>(
    _ target: WritableKeyPath<From.State, Target>,
    _ name: StaticString = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    inlineMutation: @escaping (inout Target) -> Void
  ) -> Self {
        
    AnyMutation.init(name, file, function, line) { (state: inout From.State) in
      state.update(target: target, update: inlineMutation)
    }
           
  }
  
  public static func mutationIfPresent<Target: _VergeStore_OptionalProtocol>(
    _ target: WritableKeyPath<From.State, Target>,
    _ name: StaticString = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    inlineMutation: @escaping (inout Target.Wrapped) -> Void
  ) -> Self {
    
    AnyMutation.init(name, file, function, line) { (state: inout From.State) in
      state.updateIfPresent(target: target, update: inlineMutation)
    }
    
  }
}

extension AnyMutation where From : ScopedDispatching {
  
  public static func mutationScoped(
    _ name: StaticString = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    inlineMutation: @escaping (inout From.Scoped) -> Void
  ) -> Self {
    
    self.mutation(
      From.scopedStateKeyPath,
      name,
      file,
      function,
      line,
      inlineMutation: inlineMutation
    )
    
  }
  
}

extension AnyMutation where From : ScopedDispatching, From.Scoped : _VergeStore_OptionalProtocol {
  
  public static func mutationScopedIfPresent(
    _ name: StaticString = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    inlineMutation: @escaping  (inout From.Scoped.Wrapped) -> Void) -> Self {
    
    self.mutationIfPresent(
      From.scopedStateKeyPath,
      name,
      file,
      function,
      line,
      inlineMutation: inlineMutation
    )
    
  }
  
}

