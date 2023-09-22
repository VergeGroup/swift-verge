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

struct NotEqual: Error {}

extension Comparison {

  public static func equality<T>() -> Self where Self == EqualityComparison<T> {
    .init()
  }

  /**
   TODO: Use typed comparison instead of AnyEqualityComparison.
   */
  public static func equality<each T: Equatable>() -> Self where Self == AnyEqualityComparison<(repeat each T)> {
    return .init { a, b in
      areEqual((repeat each a), (repeat each b))
    }
  }

  public static func any<T>(_ isEqual: @escaping @Sendable (T, T) -> Bool) -> Self where Self == AnyEqualityComparison<T> {
    .init(isEqual)
  }

  public static func any<T, U: Equatable>(selector: @escaping @Sendable (T) -> U) -> Self where Self == AnyEqualityComparison<T> {
    .init {
      selector($0) == selector($1)
    }
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
