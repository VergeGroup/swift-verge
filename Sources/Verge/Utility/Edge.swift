//
// Copyright (c) 2020 Hiroshi Kimura(Muukii) <muukii.app@gmail.com>
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

@available(*, deprecated, renamed: "EdgeType")
public typealias FragmentType = EdgeType

@available(*, deprecated, renamed: "Edge")
public typealias Fragment = Edge

public protocol EdgeType : Equatable {
  associatedtype State
  var wrappedValue: State { get }
  var version: UInt64 { get }
}

/**
 A structure that manages sub-state-tree from root-state-tree.

 When you create derived data for this sub-tree, you may need to activate memoization.
 The reason why it needs memoization, the derived data does not need to know if other sub-state-tree updated.
 Better memoization must know owning state-tree has been updated at least.
 To get this done, it's not always we need to support Equatable.
 It's easier to detect the difference than detect equals.

 Edge is a wrapper structure and manages version number inside.
 It increments the version number each wrapped value updated.

 Memoization can use that version if it should pass new input.

 To activate this feature, you can check this method.
 `MemoizeMap.map(_ map: @escaping (Changes<Input.Value>) -> Edge<Output>) -> MemoizeMap<Input, Output>`
 */
@propertyWrapper
public struct Edge<State>: EdgeType {

  public static func == (lhs: Edge<State>, rhs: Edge<State>) -> Bool {
    lhs.version == rhs.version
  }

  /// A number value that indicates how many times State was updated.
  public var version: UInt64 {
    _read {
      yield counter.version
    }
  }

  private(set) public var counter: NonAtomicVersionCounter = .init()
  private let middleware: Middleware?

  public init(wrappedValue: State, middleware: Middleware? = nil) {

    self.middleware = middleware

    if let middleware = middleware {
      var mutable = wrappedValue
      middleware._onSet(&mutable)
      _wrappedValue = mutable
    } else {
      _wrappedValue = wrappedValue
    }

  }

  /// A value that wrapped with Edge.
  public var wrappedValue: State {
    get {
      _wrappedValue
    }
    set {
      if let middleware = middleware {
        var mutable = newValue
        middleware._onSet(&mutable)
        _wrappedValue = mutable
      } else {
        _wrappedValue = newValue
      }
    }
  }

  private var _wrappedValue: State {
    didSet {
      counter.markAsUpdated()
    }
  }

  public var projectedValue: Edge<State> {
    self
  }

}

extension Edge where State : Equatable {
  public static func == (lhs: Edge<State>, rhs: Edge<State>) -> Bool {
    lhs.version == rhs.version || lhs.wrappedValue == rhs.wrappedValue
  }
}

extension Comparer where Input : EdgeType {

  public static func versionEquals() -> Comparer<Input> {
    Comparer<Input>.init { $0.version == $1.version }
  }
}

extension Edge {

  /**
   A handler that can modify a new state.

   ```swift
   @Edge(middleware: .assert { $0 >= 0 }) var count: Int = 0
   ```
   */
  public struct Middleware {

    let _onSet: (inout State) -> Void

    /// Initialize a instance that performs multiple middlewares from start index
    /// - Parameter onSet: It can access a new value and modify to validate something.
    public init(
      onSet: @escaping (inout State) -> Void
    ) {
      self._onSet = onSet
    }

    /// Initialize a instance that performs multiple middlewares from start index
    /// - Parameter middlewares:
    public init<C: Collection>(
      _ middlewares: C
    ) where C.Element == Middleware {

      self._onSet = { state in
        middlewares.forEach {
          $0._onSet(&state)
        }
      }

    }

    /// Raises an Swift.assertionFailure when its new value does not fit the condition.
    /// - Parameter condition:
    /// - Returns: A Middleware instance
    public static func assert(_ condition: @escaping (State) -> Bool, _ failureReason: String? = nil) -> Self {
      #if DEBUG
      return .init(onSet: { state in
        let message = failureReason ?? "[Verge] \(Edge<State>.self) raised a failure in the assertion. \(state)"
        Swift.assert(condition(state), message)
      })
      #else
      return empty()
      #endif
    }

    /// Returns a Middleware instance that does nothing.
    /// - Returns: A Middleware instance
    public static func empty() -> Self {
      return .init(onSet: { _ in })
    }

    /// Returns a Middleware that perform a closure
    /// It won't mutate the value
    ///
    /// - Returns: A Middleware instance
    public static func `do`(_ perform: @escaping (State) -> Void) -> Self {
      return .init(onSet: { perform($0) })
    }

  }

}
