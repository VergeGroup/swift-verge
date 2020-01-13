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

public protocol Filter {
  associatedtype Input
  
  /// Check if it uses input value
  /// - Parameter input:
  func check(input: Input) -> Bool
}

extension Filter {
  public func asFunction() -> (Input) -> Bool {
    check
  }
}

public enum Filters {
    
  public struct Basic<Input>: Filter {
    
    private let predicate: (Input) -> Bool
    
    public init(_ predicate: @escaping (Input) -> Bool) {
      self.predicate = predicate
    }
    
    public func check(input: Input) -> Bool {
      predicate(input)
    }
  }
  
  public struct Combined<Input>: Filter {
    
    private let predicate: (Input) -> Bool
    
    public init(and filters: [(Input) -> Bool]) {
      self.predicate = { input in
        for filter in filters {
          guard filter(input) else {
            return false
          }
        }
        return true
      }
    }
    
    public init(or filters: [(Input) -> Bool]) {
      self.predicate = { input in
        for filter in filters {
          if filter(input) {
            return true
          }
        }
        return false
      }
    }
    
    public func check(input: Input) -> Bool {
      predicate(input)
    }
    
  }
  
  
  public final class Historical<Input>: Filter {
        
    private let _isEqual: (Input) -> Bool
    
    public init<Key>(
      selector: @escaping (Input) -> Key,
      predicate: @escaping (Key, Key) -> Bool
    ) {
      
      var previousValue: Key?
      
      self._isEqual = { input in
        
        let key = selector(input)
        defer {
          previousValue = key
        }
        if let previousValue = previousValue {
          return predicate(previousValue, key)
        } else {
          return true
        }
        
      }
      
    }
    
    public func check(input: Input) -> Bool {
      _isEqual(input)
    }
    
    public func registerFirstValue(_ value: Input) {
      _ = _isEqual(value)
    }
    
  }
  
}

extension Filters.Historical {
  public convenience init<Key: Equatable>(selector: @escaping (Input) -> Key) {
    self.init(selector: selector, predicate: !=)
  }
}

extension Filters.Historical where Input : Equatable {
    
  public convenience init() {
    self.init(selector: { $0 }, predicate: !=)
  }
}
