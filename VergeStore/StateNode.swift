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

public protocol StateNodeType {
  
  associatedtype UsingState
  var storage: Storage<UsingState> { get }
  var logger: StateNodeLogger? { get }
  
}

open class AnyStateNode: Identifiable {
  
  public var id: ObjectIdentifier {
    .init(self)
  }
  
  public private(set) weak var parent: AnyStateNode?
  
  private var childNodes: [AnyStateNode] = .init()
  
  public func add(child node: AnyStateNode) {
    childNodes.append(node)
    node.parent = self
  }
  
  public func remove(child node: AnyStateNode) {
    childNodes.removeAll { $0 === node }
    node.parent = nil
  }
  
  public func removeFromParent() {
    parent?.remove(child: self)
  }
}

open class StateNode<State>: AnyStateNode, StateNodeType {
  
  public let storage: Storage<State>
  
  public private(set) var logger: StateNodeLogger?
  
  public init(initialState: State, logger: StateNodeLogger?) {
    self.storage = .init(initialState)
    self.logger = logger
    super.init()
  }
  
}

extension StateNodeType {
  
  public var state: UsingState {
    storage.value
  }
  
  @discardableResult
  public func dispatch<ReturnType>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: (StateNodeDispatchContext<Self>) throws -> ReturnType
  ) rethrows -> ReturnType {
    
    let metadata = ActionMetadata(name: name, file: file, function: function, line: line)
    
    let context = StateNodeDispatchContext<Self>.init(store: self)
    let result = try action(context)
    logger?.didDispatch(store: self, state: state, action: metadata)
    return result
    
  }
  
  public func commit(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ mutation: (inout UsingState) throws -> Void
  ) rethrows {
    
    let metadata = MutationMetadata(name: name, file: file, function: function, line: line)
    
    logger?.willCommit(store: self, state: state, mutation: metadata)
    defer {
      logger?.didCommit(store: self, state: state, mutation: metadata)
    }
    
    try storage.update { (state) in
      try mutation(&state)
    }
  }
  
}

public struct MutationMetadata {
  
  public let name: String
  public let file: StaticString
  public let function: StaticString
  public let line: UInt
  
}

public struct ActionMetadata {
  
  public let name: String
  public let file: StaticString
  public let function: StaticString
  public let line: UInt
  
}
