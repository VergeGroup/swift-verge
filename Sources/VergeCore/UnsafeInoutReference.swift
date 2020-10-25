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

@dynamicMemberLookup
public final class UnsafeInoutReference<Wrapped> {

  public private(set) var hasModified = false

  private let pointer: UnsafeMutablePointer<Wrapped>

  public init(_ pointer: UnsafeMutablePointer<Wrapped>) {
    self.pointer = pointer
  }

  public subscript<T> (dynamicMember keyPath: WritableKeyPath<Wrapped, T>) -> T {
    get {
      pointer.pointee[keyPath: keyPath]
    }
    set {
      hasModified = true
      pointer.pointee[keyPath: keyPath] = newValue
    }
  }

  public subscript<T> (dynamicMember keyPath: WritableKeyPath<Wrapped, T?>) -> T? {
    get {
      pointer.pointee[keyPath: keyPath]
    }
    set {
      markAsModified()
      pointer.pointee[keyPath: keyPath] = newValue
    }
  }

  public subscript<T> (dynamicMember keyPath: KeyPath<Wrapped, T>) -> T {
    return pointer.pointee[keyPath: keyPath]
  }

  public subscript<T> (dynamicMember keyPath: KeyPath<Wrapped, T?>) -> T? {
    return pointer.pointee[keyPath: keyPath]
  }

  public subscript<T> (keyPath keyPath: WritableKeyPath<Wrapped, T>) -> T {
    get {
      pointer.pointee[keyPath: keyPath]
    }
    set {
      markAsModified()
      pointer.pointee[keyPath: keyPath] = newValue
    }
  }

  public subscript<T> (keyPath keyPath: WritableKeyPath<Wrapped, T?>) -> T? {
    get {
      pointer.pointee[keyPath: keyPath]
    }
    set {
      markAsModified()
      pointer.pointee[keyPath: keyPath] = newValue
    }
  }

  public subscript<T> (keyPath keyPath: KeyPath<Wrapped, T>) -> T {
    return pointer.pointee[keyPath: keyPath]
  }

  public subscript<T> (keyPath keyPath: KeyPath<Wrapped, T?>) -> T? {
    return pointer.pointee[keyPath: keyPath]
  }

  /**
   Replace the wrapped value with a new value.

   We can't overload `=` operator.
   https://docs.swift.org/swift-book/LanguageGuide/AdvancedOperators.html
   */
  public func replace(with newValue: Wrapped) {
    markAsModified()
    pointer.pointee = newValue
  }

  public func markAsModified() {
    hasModified = true
  }

  public func map<U, Result>(keyPath: WritableKeyPath<Wrapped, U>, perform: (UnsafeInoutReference<U>) throws -> Result) rethrows -> Result {
    try withUnsafeMutablePointer(to: &pointer.pointee[keyPath: keyPath]) { (pointer) in
      let ref = UnsafeInoutReference<U>.init(pointer)
      defer {
        self.hasModified = ref.hasModified
      }
      return try perform(ref)
    }
  }

  public func map<U, Result>(keyPath: WritableKeyPath<Wrapped, U?>, perform: (UnsafeInoutReference<U>?) throws -> Result) rethrows -> Result {

    guard pointer.pointee[keyPath: keyPath] != nil else {
      return try perform(nil)
    }

    return try withUnsafeMutablePointer(to: &pointer.pointee[keyPath: keyPath]!) { (pointer) in
      let ref = UnsafeInoutReference<U>.init(pointer)
      defer {
        self.hasModified = ref.hasModified
      }
      return try perform(ref)
    }

  }

}
