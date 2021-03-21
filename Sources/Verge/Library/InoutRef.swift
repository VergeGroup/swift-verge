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

/**
 A reference object that manages a reference of the value type instance in order to achieve the followings:
   - Tracking the properties which are modified.
   - Tracking where modifications have happened.
   - Doing the above things without copying.
 
 - Warning: Do not retain this object anywhere.
 */
@dynamicMemberLookup
public final class InoutRef<Wrapped> {

  // MARK: - Nested types

  /**
   A representation that how modified the properties of the wrapped value.
   */
  public enum Modification: Hashable, CustomDebugStringConvertible {
    case determinate(keyPaths: Set<PartialKeyPath<Wrapped>>)
    case indeterminate

    public var debugDescription: String {
      switch self {
      case .indeterminate:
        return "indeterminate"
      case .determinate(let keyPaths):
        return "Modified:\n" + keyPaths.map {
          "  \($0)"
        }
        .joined(separator: "\n")
      }
    }
  }

  // MARK: - Properties
  
  /// - Attention: non-atomic property
  public private(set) var traces: [MutationTrace] = []

  public var modification: Modification? {

    guard nonatomic_hasModified else {
      return nil
    }

    guard !nonatomic_wasModifiedIndeterminate else {
      return .indeterminate
    }
    
    return .determinate(keyPaths: nonatomic_modifiedKeyPaths)
  }

  private(set) var nonatomic_hasModified = false

  private lazy var nonatomic_modifiedKeyPaths: Set<PartialKeyPath<Wrapped>> = .init()

  private var nonatomic_wasModifiedIndeterminate = false

  private let pointer: UnsafeMutablePointer<Wrapped>

  /// A wrapped value
  /// You may use this property to call the mutating method which `Wrapped` has.
  public var wrapped: Wrapped {
    _read {
      yield pointer.pointee
    }
    _modify {
      markAsModified()
      yield &pointer.pointee
    }
  }

  // MARK: - Initializers

  /**
   Creates an instance

   You should take care of using the pointer of value.
   Using always `withUnsafeMutablePointer` to pass it, otherwise Swift might crash with Memory error.
   */
  public init(_ pointer: UnsafeMutablePointer<Wrapped>) {
    self.pointer = pointer
  }

  // MARK: - Functions
  
  /**
  Returns a Boolean value that indicates whether the property pointed by the specified KeyPath has been modified.
  If the modification indicates indeterminate, returns always true.
 
  - Warning: Returns false even child properties modified if specified parent keypath.
  */
  public func hasModified<U>(_ keyPath: KeyPath<Wrapped, U>) -> Bool {
    
    guard nonatomic_hasModified else {
      return false
    }
    
    if keyPath == \Wrapped.self {
      return nonatomic_hasModified
    } else {
      
      guard let modification = modification else {
        return false
      }
      
      switch modification {
      case .determinate(let keyPaths):
        return keyPaths.contains(keyPath)
      case .indeterminate:
        return true
      }
      
    }
  }
  
  func append(trace: MutationTrace) {
    traces.append(trace)
  }
  
  func append(traces otherTraces: [MutationTrace]) {
    traces.append(contentsOf: otherTraces)
  }

  public subscript<T> (dynamicMember keyPath: WritableKeyPath<Wrapped, T>) -> T {
    _read {
      yield pointer.pointee[keyPath: keyPath]
    }
    _modify {
      maskAsModified(on: keyPath)
      yield &pointer.pointee[keyPath: keyPath]
    }
  }

  public subscript<T> (dynamicMember keyPath: WritableKeyPath<Wrapped, T?>) -> T? {
    _read {
      yield pointer.pointee[keyPath: keyPath]
    }
    _modify {
      maskAsModified(on: keyPath)
      yield &pointer.pointee[keyPath: keyPath]
    }
  }

  public subscript<T> (dynamicMember keyPath: KeyPath<Wrapped, T>) -> T {
    _read {
      yield pointer.pointee[keyPath: keyPath]
    }
  }

  public subscript<T> (dynamicMember keyPath: KeyPath<Wrapped, T?>) -> T? {
    _read {
      yield pointer.pointee[keyPath: keyPath]
    }
  }

  public subscript<T> (keyPath keyPath: WritableKeyPath<Wrapped, T>) -> T {
    _read {
      yield pointer.pointee[keyPath: keyPath]
    }
    _modify {
      maskAsModified(on: keyPath)
      yield &pointer.pointee[keyPath: keyPath]
    }
  }

  public subscript<T> (keyPath keyPath: WritableKeyPath<Wrapped, T?>) -> T? {
    _read {
      yield pointer.pointee[keyPath: keyPath]
    }
    _modify {
      maskAsModified(on: keyPath)
      yield &pointer.pointee[keyPath: keyPath]
    }
  }

  public subscript<T> (keyPath keyPath: KeyPath<Wrapped, T>) -> T {
    _read {
      yield pointer.pointee[keyPath: keyPath]
    }
  }

  public subscript<T> (keyPath keyPath: KeyPath<Wrapped, T?>) -> T? {
    _read {
      yield pointer.pointee[keyPath: keyPath]
    }
  }

  private func maskAsModified(on keyPath: PartialKeyPath<Wrapped>) {
    nonatomic_modifiedKeyPaths.insert(keyPath)
    nonatomic_hasModified = true
  }

  /// Marks as modified
  /// `modification` property becomes to `.indeterminate`.
  public func markAsModified() {
    nonatomic_hasModified = true
    nonatomic_wasModifiedIndeterminate = true
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

  /// Modify the wrapped value with native accessing (without KeyPath + DynamicMemberLookup)
  ///
  /// Attention: Using this method makes modifition indeterminate.
  @available(*, renamed: "modifyDirectly")
  @discardableResult
  public func modify<Return>(_ perform: (inout Wrapped) throws -> Return) rethrows -> Return {
    return try modifyDirectly(perform)
  }

  /// Modify the wrapped value with native accessing (without KeyPath + DynamicMemberLookup)
  ///
  /// Attention: Using this method makes modifition indeterminate.
  @discardableResult
  public func modifyDirectly<Return>(_ perform: (inout Wrapped) throws -> Return) rethrows -> Return {
    markAsModified()
    return try perform(&pointer.pointee)
  }
    
  /**
   Runs given closure with its Type and itself.
   It helps to run static functions to modify state.
   
   ```swift
   struct State {
     ...
   
     static func modifyForSomething(in ref: InoutRef<Self>, argments: ...) {
       
     }
   }
   ```
   
   ```swift
   commit {
     $0.withType { type, ref in
       type.modifyForSomething(in: ref, arguments: ...)
     }
   }
   ```
   
   The reason why it does not use a mutating function in the state is to keep InoutRef's modifications are determinate.
   
   - SeeAlso: InoutRef<Wrapped>.Modification
   */
  public func withType<Return>(_ perform: (Wrapped.Type, InoutRef<Wrapped>) throws -> Return) rethrows -> Return {
    try perform(Wrapped.self, self)
  }

  /**
   Returns a tantative InoutRef that projects the value specified by KeyPath.
   That InoutRef must be used only in the given perform closure.
   */
  public func map<U, Result>(keyPath: WritableKeyPath<Wrapped, U>, perform: (inout InoutRef<U>) throws -> Result) rethrows -> Result {
    try withUnsafeMutablePointer(to: &pointer.pointee[keyPath: keyPath]) { (pointer) in
      var ref = InoutRef<U>.init(pointer)
      defer {
        self.nonatomic_hasModified = ref.nonatomic_hasModified
        self.nonatomic_wasModifiedIndeterminate = ref.nonatomic_wasModifiedIndeterminate

        let appended = ref.nonatomic_modifiedKeyPaths.compactMap {
          (keyPath as PartialKeyPath<Wrapped>).appending(path: $0)
        }

        self.nonatomic_modifiedKeyPaths.formUnion(appended)
      }
      return try perform(&ref)
    }
  }

  /**
   Returns a tantative InoutRef that projects the value specified by KeyPath.
   That InoutRef must be used only in the given perform closure.
   */
  public func map<U, Result>(keyPath: WritableKeyPath<Wrapped, U?>, perform: (inout InoutRef<U>?) throws -> Result) rethrows -> Result {

    guard pointer.pointee[keyPath: keyPath] != nil else {
      var _nil: InoutRef<U>! = .none
      return try perform(&_nil)
    }

    return try withUnsafeMutablePointer(to: &pointer.pointee[keyPath: keyPath]!) { (pointer) in
      var ref: InoutRef<U>! = InoutRef<U>.init(pointer)
      defer {
        self.nonatomic_hasModified = ref.nonatomic_hasModified
        self.nonatomic_wasModifiedIndeterminate = ref.nonatomic_wasModifiedIndeterminate

        let appended = ref.nonatomic_modifiedKeyPaths.compactMap {
          (keyPath as PartialKeyPath<Wrapped>).appending(path: $0)
        }

        self.nonatomic_modifiedKeyPaths.formUnion(appended)

      }
      return try perform(&ref)
    }

  }
  
}

/// Do not retain on anywhere.
@dynamicMemberLookup
public final class ReadRef<Wrapped> {

  private let pointer: UnsafePointer<Wrapped>

  /// A wrapped value
  /// You may use this property to call the mutating method which `Wrapped` has.
  public var wrapped: Wrapped {
    _read {
      yield pointer.pointee
    }
  }

  // MARK: - Initializers

  /**
   Creates an instance

   You should take care of using the pointer of value.
   Using always `withUnsafeMutablePointer` to pass it, otherwise Swift might crash with Memory error.
   */
  public init(_ pointer: UnsafePointer<Wrapped>) {
    self.pointer = pointer
  }

  // MARK: - Functions

  public subscript<T> (dynamicMember keyPath: KeyPath<Wrapped, T>) -> T {
    _read {
      yield pointer.pointee[keyPath: keyPath]
    }
  }

  public subscript<T> (dynamicMember keyPath: KeyPath<Wrapped, T?>) -> T? {
    _read {
      yield pointer.pointee[keyPath: keyPath]
    }
  }

  public subscript<T> (keyPath keyPath: KeyPath<Wrapped, T>) -> T {
    _read {
      yield pointer.pointee[keyPath: keyPath]
    }
  }

  public subscript<T> (keyPath keyPath: KeyPath<Wrapped, T?>) -> T? {
    _read {
      yield pointer.pointee[keyPath: keyPath]
    }
  }

  func map<U, Result>(keyPath: KeyPath<Wrapped, U>, perform: (inout ReadRef<U>) throws -> Result) rethrows -> Result {

    try withUnsafePointer(to: pointer.pointee[keyPath: keyPath]) { (pointer) in
      var ref = ReadRef<U>.init(pointer)
      return try perform(&ref)
    }
  }

  func map<U, Result>(keyPath: KeyPath<Wrapped, U?>, perform: (inout ReadRef<U>?) throws -> Result) rethrows -> Result {

    guard pointer.pointee[keyPath: keyPath] != nil else {
      var _nil: ReadRef<U>! = .none
      return try perform(&_nil)
    }

    return try withUnsafePointer(to: pointer.pointee[keyPath: keyPath]!) { (pointer) in
      var ref: ReadRef<U>! = ReadRef<U>.init(pointer)
      return try perform(&ref)
    }

  }

}
