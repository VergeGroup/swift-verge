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

public protocol StoreMiddlewareType<State>: Sendable {

  associatedtype State

  @Sendable
  func modify(modifyingState: inout State, transaction: inout Transaction, current: Changes<State>)

}

public struct AnyStoreMiddleware<State>: StoreMiddlewareType, Sendable {

  private let closure: @Sendable (_ modifyingState: inout State, _ transaction: inout Transaction, _ current: Changes<State>) -> Void

  init(
    modify: @escaping @Sendable (
      _ modifyingState: inout State, _ transaction: inout Transaction, _ current: Changes<State>
    )
      -> Void
  ) {
    self.closure = modify
  }

  public func modify(
    modifyingState: inout State, transaction: inout Transaction, current: Changes<State>
  ) {
    self.closure(&modifyingState, &transaction, current)
  }

}

extension StoreMiddlewareType {

  /**
   Creates an instance that commits mutations according to the original committing.
   */
  public static func modify<State: Equatable>(
    modify: @escaping @Sendable (
      _ modifyingState: inout State, _ transaction: inout Transaction, _ current: Changes<State>
    )
      -> Void
  ) -> Self where Self == AnyStoreMiddleware<State> {
    return .init(modify: modify)
  }

}
