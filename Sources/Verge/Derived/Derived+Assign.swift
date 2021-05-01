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

extension Derived {
  
  /**
   Assigns a derived's value to a property of a store.

   - Returns: a cancellable. See detail of handling cancellable from `VergeAnyCancellable`'s docs
   */
  public func assign(
    to binder: @escaping (Changes<Value>) -> Void
  ) -> VergeAnyCancellable {
    sinkValue(queue: .passthrough) { c in
      binder(c)
    }
  }
  
}

extension StoreType {

  /**
   Assigns a Store's state to a property of a store.

   - Returns: a cancellable. See detail of handling cancellable from `VergeAnyCancellable`'s docs
   */
  public func assign(
    to binder: @escaping (Changes<State>) -> Void
  ) -> VergeAnyCancellable {
    asStore().sinkState(queue: .passthrough) { c in
      binder(c)
    }
  }

}

#if canImport(Combine)

import Combine

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension Publisher {

  /**
   Assigns a Publishers's value to a property of a store.

   - Attention: Store won't be retained.
   - Returns: a cancellable. See detail of handling cancellable from `VergeAnyCancellable`'s docs
   - Author: Verge
   */
  public func assign(
    to binder: @escaping (Output) -> Void
  ) -> VergeAnyCancellable {
    let cancellable = sink(receiveCompletion: { _ in }) { (value) in
      binder(value)
    }
    return .init {
      cancellable.cancel()
    }
  }

}

#endif
