//
// Copyright (c) 2020 Hiroshi Kimura(Muukii) <muuki.app@gmail.com>
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
 
 An object that contains 2 instances (old, new)
 Use-case is to know how it did change.

 ```
 struct MyState {
   var name: String
   var age: String
   var height: String
 }
 ```
 
 ```
 let changes: Changes<MyState>
 ```
 
 It can be accessed with properties of MyState by dynamicMemberLookup
 ```
 changes.name
 ```
 
 It would be helpful to update UI partially
 ```
 func updateUI(changes: Changes<MyState>) {
 
   changes.ifChanged(\.name) { name in
     // update UI
   }
 
   changes.ifChanged(\.age) { age in
     // update UI
   }
 
   changes.ifChanged(\.height) { height in
     // update UI
   }
 }
 ```
 */
@dynamicMemberLookup
public struct Changes<Value> {
  
  public private(set) var old: Value?
  public private(set) var new: Value
  
  public init(old: Value?, new: Value) {
    self.old = old
    self.new = new
  }
  
  public subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T {
    _read {
      yield new[keyPath: keyPath]
    }
  }
  
  /// Returns boolean that indicates value specified by keyPath contains changes with compared old and new.
  ///
  @inline(__always)
  public func hasChanges<T: Equatable>(_ keyPath: KeyPath<Value, T>) -> Bool {
    let selectedOld = old?[keyPath: keyPath]
    let selectedNew = new[keyPath: keyPath]
    
    return selectedOld != selectedNew
  }
  
  /// Do a closure if value specified by keyPath contains changes.
  public func ifChanged<T: Equatable>(_ keyPath: KeyPath<Value, T>, _ perform: (T) throws -> Void) rethrows {
    
    guard hasChanges(keyPath) else { return }
    try perform(new[keyPath: keyPath])
  }
  
  public func map<U>(_ transform: (Value) throws -> U) rethrows -> Changes<U> {
    .init(old: try old.map(transform), new: try transform(new))
  }
  
  public func makeNextChanges(with nextNewValue: Value) -> Changes<Value> {
    .init(old: self.new, new: nextNewValue)
  }
  
  public mutating func update(with nextNewValue: Value) {
    self.old = self.new
    self.new = nextNewValue
  }
  
}

extension Changes where Value : Equatable {
  
  public var hasChanges: Bool {
    old != new
  }
}
