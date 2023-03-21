//
// Copyright (c) 2021 muukii
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
 Value storage for commit operation.
 The commit operation accepts adding context about its operation.
 It brings contextual operation into state-driven.
 For instance, same value changes but it's not the same meaning actually.

 ``Changes`` has ``Changes/transaction`` property.
 */
public struct Transaction {
  
  private var values: [ObjectIdentifier : Any] = [:]

  public subscript<K>(key: K.Type) -> K.Value where K : TransactionKey {
    get {
      values[ObjectIdentifier(K.self)] as? K.Value ?? K.defaultValue
    }
    mutating set {
      values[ObjectIdentifier(K.self)] = newValue
    }
  }

  public init() {
  }

}

/**
 A type based key for transaction.
 It's like SwiftUI's EnvironmentValue.
 Making a new type as key, gat and set values over the key.
 It's much safer than using string directly as avoiding conflict by using same value.

 ```
 enum MyKey: TransactionKey {
   static var defaultValue: String? { nil }
 }
 ```

 ```
 extension Transaction {
   var myValue: String? {
     get {
       self[MyKey.self]
     }
     set {
       self[MyKey.self] = newValue
     }
   }
 }
 ```
 */
public protocol TransactionKey {

  associatedtype Value

  static var defaultValue: Value { get }

}
