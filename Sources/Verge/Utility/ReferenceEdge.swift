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
 Copy-on-Write property wrapper.
 Stores the value in reference type storage.
 */
@propertyWrapper
@dynamicMemberLookup
public struct ReferenceEdge<State>: EdgeType {

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.storage === rhs.storage
  }

  public subscript <U>(dynamicMember keyPath: KeyPath<State, U>) -> U {
    _read { yield wrappedValue[keyPath: keyPath] }
  }

  public subscript <U>(dynamicMember keyPath: KeyPath<State, U?>) -> U? {
    _read { yield wrappedValue[keyPath: keyPath] }
  }

  public subscript <U>(dynamicMember keyPath: WritableKeyPath<State, U>) -> U {
    _read { yield wrappedValue[keyPath: keyPath] }
    _modify { yield &wrappedValue[keyPath: keyPath] }
  }

  public subscript <U>(dynamicMember keyPath: WritableKeyPath<State, U?>) -> U? {
    _read { yield wrappedValue[keyPath: keyPath] }
    _modify { yield &wrappedValue[keyPath: keyPath] }
  }


  public init(wrappedValue: consuming State) {
    self.storage = ReferenceEdgeStorage(consume wrappedValue)
  }

  public var _storagePointer: OpaquePointer {
    return .init(Unmanaged.passUnretained(storage).toOpaque())
  }

  private var storage: ReferenceEdgeStorage<State>

  public var wrappedValue: State {
    _read {
      yield storage.value
    }
    _modify {
      let oldValue = storage.value
      if isKnownUniquelyReferenced(&storage) {
        // modify
        yield &storage.value
      } else {
        // make copy
        storage = ReferenceEdgeStorage(oldValue)
        yield &storage.value
      }
    }
  }

  public var projectedValue: Self {
    self
  }

  public func read<T>(_ thunk: (borrowing State) -> T) -> T {
    thunk(wrappedValue)
  }

}

extension ReferenceEdge where State : Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.storage === rhs.storage || lhs.wrappedValue == rhs.wrappedValue
  }
}

final class ReferenceEdgeStorage<Value>: @unchecked Sendable {

  var value: Value

  init(_ value: consuming Value) {
    self.value = value
  }

  func read<T>(_ thunk: (borrowing Value) -> T) -> T {
    thunk(value)
  }

}

extension ReferenceEdge: Sendable where State: Sendable {

}
