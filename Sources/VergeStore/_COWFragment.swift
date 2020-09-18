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

/**
 A structure that manages sub-state-tree from root-state-tree.

 When you create derived data for this sub-tree, you may need to activate memoization.
 The reason why it needs memoization, the derived data does not need to know if other sub-state-tree updated.
 Better memoization must know owning state-tree has been updated at least.
 To get this done, it's not always we need to support Equatable.
 It's easier to detect the difference than detect equals.

 Fragment is a wrapper structure and manages version number inside.
 It increments the version number each wrapped value updated.

 Memoization can use that version if it should pass new input.

 To activate this feature, you can check this method.
 `MemoizeMap.map(_ map: @escaping (Changes<Input.Value>) -> Fragment<Output>) -> MemoizeMap<Input, Output>`
 */
@propertyWrapper
public struct _COWFragment<State>: EdgeType {

  private final class Storage {

    var value: State

    init(_ value: State) {
      self.value = value
    }

  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.storage === rhs.storage || lhs.version == rhs.version
  }

  public var version: UInt64 {
    _read {
      yield counter.version
    }
  }

  private(set) public var counter: NonAtomicVersionCounter = .init()

  public init(wrappedValue: State) {
    self.storage = Storage(wrappedValue)
  }

  private var storage: Storage

  public var wrappedValue: State {
    _read {
      yield storage.value
    }
    _modify {
      counter.markAsUpdated()
      let oldValue = storage.value
      if isKnownUniquelyReferenced(&storage) {
        yield &storage.value
      } else {
        storage = Storage(oldValue)
        yield &storage.value
      }
    }
  }

  public var projectedValue: Self {
    self
  }

}

extension _COWFragment where State : Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.storage === rhs.storage || lhs.version == rhs.version || lhs.wrappedValue == rhs.wrappedValue
  }
}


