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

public protocol ActionBaseType {
  
}

public protocol ActionType: ActionBaseType {
  
  associatedtype Dispatcher: DispatcherType
  associatedtype Result
  func run(context: DispatcherContext<Dispatcher>) -> Result
}

public protocol TryActionType: ActionBaseType {
  
  associatedtype Dispatcher: DispatcherType
  associatedtype Result
  func run(context: DispatcherContext<Dispatcher>) throws -> Result
}

public struct AnyAction<Dispatcher: DispatcherType, Result>: ActionType {
  
  let _action: (DispatcherContext<Dispatcher>) -> Result
  public let metadata: ActionMetadata
  
  public init(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: @escaping (DispatcherContext<Dispatcher>) -> Result
  ) {
    
    self.metadata = .init(name: name, file: file, function: function, line: line)
    self._action = action
    
  }
  
  public func run(context: DispatcherContext<Dispatcher>) -> Result {
    _action(context)
  }
}

public struct TryAnyAction<Dispatcher: DispatcherType, Result>: TryActionType {
  
  let _action: (DispatcherContext<Dispatcher>) throws -> Result
  public let metadata: ActionMetadata
  
  public init(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: @escaping (DispatcherContext<Dispatcher>) throws -> Result
  ) {
    
    self.metadata = .init(name: name, file: file, function: function, line: line)
    self._action = action
    
  }
  
  public func run(context: DispatcherContext<Dispatcher>) throws -> Result {
    try _action(context)
  }
}

extension AnyAction {
  
  public static func action(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: @escaping (DispatcherContext<Dispatcher>) -> Result
  ) -> Self {
    self.init(name, file, function, line, action)
  }
  
}

extension TryAnyAction {
  
  public static func tryAction(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: @escaping (DispatcherContext<Dispatcher>) throws -> Result
  ) -> Self {
    self.init(name, file, function, line, action)
  }
  
}
