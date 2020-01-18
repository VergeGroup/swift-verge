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

public protocol MutationBaseType {
  
}

public protocol MutationType: MutationBaseType {
  associatedtype Result
  associatedtype State
  func mutate(state: inout State) -> Result
}

public protocol TryMutationType: MutationBaseType {
  associatedtype Result
  associatedtype State
  func mutate(state: inout State) throws -> Result
}

public struct AnyMutation<State: StateType, Result>: MutationType {
  
  let _mutate: (inout State) -> Result
  
  public let metadata: MutationMetadata
  
  public init(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    mutate: @escaping (inout State) -> Result
  ) {
    
    self.metadata = .init(name: name, file: file, function: function, line: line)
    self._mutate = mutate
  }
  
  public func mutate(state: inout State) -> Result {
    _mutate(&state)
  }
  
}

public struct TryAnyMutation<State: StateType, Result>: TryMutationType {
  
  let _mutate: (inout State) throws -> Result
  
  public let metadata: MutationMetadata
  
  public init(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    mutate: @escaping (inout State) throws -> Result
  ) {
    
    self.metadata = .init(name: name, file: file, function: function, line: line)
    self._mutate = mutate
  }
  
  public func mutate(state: inout State) throws -> Result {
    try _mutate(&state)
  }
  
}

extension AnyMutation {
  
  public static func mutation(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    inlineMutation: @escaping (inout State) -> Result
  ) -> Self {
    
    self.init(name, file, function, line, mutate: inlineMutation)
    
  }
  
  public static func mutation<Target>(
    _ target: WritableKeyPath<State, Target>,
    _ name: StaticString = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    inlineMutation: @escaping (inout Target) -> Result
  ) -> Self {
    
    self.init(name.description, file, function, line) { (state: inout State) in
      state.update(target: target, update: inlineMutation)
    }
    
  }
  
}

extension TryAnyMutation {
  
  public static func tryMutation(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    inlineMutation: @escaping (inout State) throws -> Result
  ) -> Self {
    
    self.init(name, file, function, line, mutate: inlineMutation)
    
  }
  
  public static func tryMutation<Target>(
    _ target: WritableKeyPath<State, Target>,
    _ name: StaticString = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    inlineMutation: @escaping (inout Target) throws -> Result
  ) -> Self {
    
    self.init(name.description, file, function, line) { (state: inout State) in
      try state.update(target: target, update: inlineMutation)
    }
    
  }
  
}
