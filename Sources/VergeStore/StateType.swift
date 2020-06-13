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

/// A protocol provides stuff to help to mutate itself.
/// Not required to use with Store's state
///
/// You may use ExtendedStateType to define computed property with caching to be performant.
public protocol StateType {
  
}

/// A container object to group getter properties.
/// Mainly it would be used with dynamicMemberLookup.
/// Therefore it must be initialized with no args.
public protocol ExtendedType {
  
  /// Currently limitation
  /// To get better performance, return shared initialized instance
  ///
  /// This property will be accessed by using computed property
  ///
  /// ```
  /// static let instance: YourExtendedType = .init()
  /// ```
  ///
  static var instance: Self { get }
}

/** A protocol extended from StateType
 ```
 struct State: ExtendedStateType {
 
   var name: String = "muukii"

   struct Extended: ExtendedType {
      
     let nameCount = Field.Computed(\.value.count)
       .ifChanged(keySelector: \.value, comparer: .init(==))
      
    }
 }
 
 let store: MyStore<State, Never>
 
 let value: Int = store.changes.computed.nameCount
 ```
*/
public protocol ExtendedStateType: StateType {
  
  associatedtype Extended: ExtendedType
}

public enum StateUpdatingError: Swift.Error {
  case targetWasNull
}

public protocol _VergeStore_OptionalProtocol {
  associatedtype Wrapped
  var _vergestore_wrappedValue: Wrapped? { get set }
}

extension Optional: _VergeStore_OptionalProtocol {
  
  public var _vergestore_wrappedValue: Wrapped? {
    get {
      return self
    }
    mutating set {
      self = newValue
    }
  }
}

extension StateType {
      
  public mutating func updateTryPresent<T: _VergeStore_OptionalProtocol, Return>(
    target keyPath: WritableKeyPath<Self, T>,
    update: (inout T.Wrapped) throws -> Return
  ) throws -> Return {
    
    guard self[keyPath: keyPath]._vergestore_wrappedValue != nil else { throw StateUpdatingError.targetWasNull }
    return try update(&self[keyPath: keyPath]._vergestore_wrappedValue!)
  }
  
  public mutating func update<T, Return>(target keyPath: WritableKeyPath<Self, T>, update: (inout T) throws -> Return) rethrows -> Return {
    try update(&self[keyPath: keyPath])
  }
  
  public mutating func update<Return>(update: (inout Self) throws -> Return) rethrows -> Return {
    try update(&self)
  }
  
}
