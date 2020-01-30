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

fileprivate final class PreviousValueRef<T> {
  var value: T?
  init() {}
}


/// A Filter that compares with previous value.
public final class HistoricalComparer<Input> {
  
  private let _isEqual: (Input) -> Bool
  
  public init<Key, C: Comparer>(
    selector: @escaping (Input) -> Key,
    comparer: C
  ) where C.Input == Key {
    
    let ref = PreviousValueRef<Key>()
    
    self._isEqual = { input in
      
      let key = selector(input)
      defer {
        ref.value = key
      }
      if let previousValue = ref.value {
        return comparer.equals(previousValue: previousValue, newValue: key)
      } else {
        return false
      }
      
    }
    
  }
  
  public func equals(input: Input) -> Bool {
    _isEqual(input)
  }
  
  public func registerFirstValue(_ value: Input) {
    _ = _isEqual(value)
  }
  
  public func asFunction() -> (Input) -> Bool {
    equals
  }
  
}

public protocol Comparer {
  associatedtype Input
  
  /// Check if it uses input value
  /// - Parameter input:
  func equals(previousValue: Input, newValue: Input) -> Bool
}

extension Comparer {
  public func asFunction() -> (Input, Input) -> Bool {
    equals
  }
}

public struct AnyComparerFragment<Input>: Comparer {
  private let equals: (Input, Input) -> Bool
  
  public init(_ equals: @escaping (Input, Input) -> Bool) {
    self.equals = equals
  }
  
  public func equals(previousValue: Input, newValue: Input) -> Bool {
    equals(previousValue, newValue)
  }
}

public struct CombinedComparerFragment<Input>: Comparer {
  
  private let equals: (Input, Input) -> Bool
  
  public init(and filters: [(Input, Input) -> Bool]) {
    self.equals = { pre, new in
      for filter in filters {
        guard filter(pre, new) else {
          return false
        }
      }
      return true
    }
  }
  
  public init(or filters: [(Input, Input) -> Bool]) {
    self.equals = { pre, new in
      for filter in filters {
        if filter(pre, new) {
          return true
        }
      }
      return false
    }
  }
  
  public func equals(previousValue: Input, newValue: Input) -> Bool {
    equals(previousValue, newValue)
  }
  
  public func asAny() -> AnyComparerFragment<Input> {
    .init(equals)
  }
  
}

