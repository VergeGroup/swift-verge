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
import StateStruct

public struct InoutRef<Wrapped> {
  
  public enum Modification {
    case graph(PropertyNode)
    case indeterminate
  }

  // MARK: - Properties

  nonisolated(unsafe) private let pointer: UnsafeMutablePointer<Wrapped>

  /// A wrapped value
  /// You may use this property to call the mutating method which `Wrapped` has.
  public var wrapped: Wrapped {
    _read {
      yield pointer.pointee
    }
    _modify {
      yield &pointer.pointee
    }
  }
  
  private(set) var modification: Modification?

  public var hasModified: Bool {
    guard let modification else {
      return false
    }    
    switch modification {
    case .graph(let graph):
      return !graph.isEmpty
    case .indeterminate:
      return true
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

  public mutating func modify<T>(_ perform: (inout Wrapped) throws -> T) rethrows -> T {
    
    if pointer.pointee is TrackingObject {
      var result: T!
      
      var modifyingResult = try (pointer.pointee as! TrackingObject).tracking(using: {
        switch modification {
        case .graph(let graph):
          return graph
        default:
          return nil
        }
      }()) {
        result = try perform(&pointer.pointee)
      }
      
      modifyingResult.graph.shakeAsWrite()
      
      let graph = modifyingResult.graph
      
      self.modification = .graph(graph)
      
#if DEBUG
      Log.writeGraph.debug("Modified: \(graph.prettyPrint())")
#endif
      
      return result
    } else {
      
      let r = try perform(&pointer.pointee)
      
      modification = .indeterminate
      
      return r
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

  public subscript<T>(dynamicMember keyPath: KeyPath<Wrapped, T>) -> T {
    _read {
      yield pointer.pointee[keyPath: keyPath]
    }
  }

  public subscript<T>(dynamicMember keyPath: KeyPath<Wrapped, T?>) -> T? {
    _read {
      yield pointer.pointee[keyPath: keyPath]
    }
  }

  public subscript<T>(keyPath keyPath: KeyPath<Wrapped, T>) -> T {
    _read {
      yield pointer.pointee[keyPath: keyPath]
    }
  }

  public subscript<T>(keyPath keyPath: KeyPath<Wrapped, T?>) -> T? {
    _read {
      yield pointer.pointee[keyPath: keyPath]
    }
  }

  func map<U, Result>(keyPath: KeyPath<Wrapped, U>, perform: (inout ReadRef<U>) throws -> Result)
    rethrows -> Result
  {

    try withUnsafePointer(to: pointer.pointee[keyPath: keyPath]) { (pointer) in
      var ref = ReadRef<U>.init(pointer)
      return try perform(&ref)
    }
  }

  func map<U, Result>(keyPath: KeyPath<Wrapped, U?>, perform: (inout ReadRef<U>?) throws -> Result)
    rethrows -> Result
  {

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
