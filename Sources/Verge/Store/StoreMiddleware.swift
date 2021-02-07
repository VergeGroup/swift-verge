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
 Middleware enables us to do extra operations according to dispatched commits in Store.
 */
open class StoreMiddleware<State> {
  
  open func mutate(state: inout InoutRef<State>) {
    
  }
    
  /**
   Creates an instance that commits mutations according to the original committing.
   */
  public static func unifiedMutation(_ mutate: @escaping (inout InoutRef<State>) -> Void) -> AnonymousStoreMiddleware<State> {
    return .init(mutate: mutate)
  }
  
}

/**
 A closure-based middleware. It enables us to create middleware without creating sub-class.
 */
public final class AnonymousStoreMiddleware<State>: StoreMiddleware<State> {
  
  private let _mutate: (inout InoutRef<State>) -> Void
  
  public init(mutate: @escaping (inout InoutRef<State>) -> Void) {
    self._mutate = mutate
  }

  public override func mutate(state: inout InoutRef<State>) {
    _mutate(&state)
  }
}
