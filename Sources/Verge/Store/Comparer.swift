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
import os.log

public protocol Comparison<Input>: Sendable {
  associatedtype Input

  @Sendable
  func callAsFunction(_ lhs: Input, _ rhs: Input) -> Bool
}

extension Comparison {

  public static func equality<T>() -> Self where Self == EqualityComparison<T> {
    .init()
  }

  public static func alwaysFalse<T>() -> Self where Self == FalseComparison<T> {
    .init()
  }

}

extension Comparison {

  public func and<C: Comparison>(_ otherExpression: C) -> AndComparison<Input, Self, C> {
    .init(self, otherExpression)
  }

  public func or<C: Comparison>(_ otherExpression: C) -> OrComparison<Input, Self, C> {
    .init(self, otherExpression)
  }
}

public struct FalseComparison<Input>: Comparison {
  public init() {}

  public func callAsFunction(_ lhs: Input, _ rhs: Input) -> Bool {
    return false
  }
}

public struct EqualityComparison<Input: Equatable>: Comparison {

  public init() {}

  @Sendable
  public func callAsFunction(_ lhs: Input, _ rhs: Input) -> Bool {
    lhs == rhs
  }

}

public struct AnyEqualityComparison<Input>: Comparison {

  private let closure: @Sendable (Input, Input) -> Bool

  public init(_ isEqual: @escaping @Sendable (Input, Input) -> Bool) {
    self.closure = isEqual
  }

  public func callAsFunction(_ lhs: Input, _ rhs: Input) -> Bool {
    closure(lhs, rhs)
  }

}

public struct AndComparison<Input, C1: Comparison, C2: Comparison>: Comparison where C1.Input == Input, C2.Input == Input {

  public let c1: C1
  public let c2: C2

  public init(_ c1: C1, _ c2: C2) {
    self.c1 = c1
    self.c2 = c2
  }

  public func callAsFunction(_ lhs: Input, _ rhs: Input) -> Bool {
    c1(lhs, rhs) && c2(lhs, rhs)
  }
}

public struct OrComparison<Input, C1: Comparison, C2: Comparison>: Comparison where C1.Input == Input, C2.Input == Input  {
  public let c1: C1
  public let c2: C2

  public init(_ c1: C1, _ c2: C2) {
    self.c1 = c1
    self.c2 = c2
  }

  public func callAsFunction(_ lhs: Input, _ rhs: Input) -> Bool {
    c1(lhs, rhs) || c2(lhs, rhs)
  }
}

/// A component that compares an input value.
/// It can be combined with other comparers.
public struct Comparer<Input> {
  
  public static var alwaysFalse: Self {
    .init { _, _ in false }
  }
  
  private let _equals: (Input, Input) -> Bool

  /// Creates an instance
  ///
  /// - Parameter equals: Return true if two inputs are equal.
  public init(
    _ equals: @escaping (Input, Input) -> Bool
  ) {
    self._equals = equals
  }
      
  /// It compares the value selected from passed selector closure
  /// - Parameter selector:
  public init<T: Equatable>(selector: @escaping (Input) -> T) {
    self.init { a, b in
      selector(a) == selector(b)
    }
  }
  
  public init<T>(selector: @escaping (Input) -> T, equals: @escaping (T, T) -> Bool) {
    self.init { a, b in
      equals(selector(a), selector(b))
    }
  }
    
  public init<T>(selector: @escaping (Input) -> T, comparer: Comparer<T>) {
    self.init { a, b in
      comparer._equals(selector(a), selector(b))
    }
  }
        
  /// Make Combined comparer
  /// - Parameter comparers:
  public init(and comparers: [Comparer<Input>]) {
    self.init { pre, new in
      for filter in comparers {
        guard filter._equals(pre, new) else {
          return false
        }
      }
      return true
    }
  }
  
  /// Make Combined comparer
  /// - Parameter comparers:
  public init(or comparers: [Comparer<Input>]) {
    self.init { pre, new in
      for filter in comparers {
        if filter._equals(pre, new) {
          return true
        }
      }
      return false
    }
  }
  
  public func equals(_ lhs: Input, _ rhs: Input) -> Bool {
    _equals(lhs, rhs)
  }

  /// Returns an curried closure
  public func curried() -> (_ lhs: Input, _ rhs: Input) -> Bool {
    _equals
  }

}

extension Comparer where Input : Equatable {  
  public init() {
    self.init(==)
  }

  public static var usingEquatable: Self {
    return .init(==)
  }
}

extension Comparer {
  
  public func and(_ otherComparer: () -> Comparer) -> Comparer {
    .init(and: [
      self,
      otherComparer()
    ])
  }
  
  public func or(_ otherComparer: () -> Comparer) -> Comparer {
    .init(or: [
      self,
      otherComparer()
    ])
  }
  
  public func debug(name: String = "", file: StaticString = #file, line: UInt = #line) -> Self {
    .init { pre, new -> Bool in
      let result = self._equals(pre,new)
      os_log("%@", log: VergeOSLogs.debugLog, type: .default, "\(file.description):\(line):\(name) result:\(result)")
      return result
    }
  }
}
