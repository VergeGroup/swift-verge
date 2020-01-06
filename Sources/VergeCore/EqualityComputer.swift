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

public final class EqualityComputer<Input> {
  
  public static func alwaysDifferent() -> EqualityComputer<Input> {
    EqualityComputer<Input>.init(selector: { _ in () }) { (_, _) -> Bool in
      return false
    }
  }
  
  public static func alwaysEquals() -> EqualityComputer<Input> {
    EqualityComputer<Input>.init(selector: { _ in () }) { (_, _) -> Bool in
      return true
    }
  }
  
  private let _isEqual: (Input) -> Bool
  
  public init(_ sources: [EqualityComputer<Input>]) {
    self._isEqual = { input in
      for source in sources {
        guard source.isEqual(value: input) else {
          return false
        }
      }
      return true
    }
  }
  
  public init<Key>(
    selector: @escaping (Input) -> Key,
    equals: @escaping (Key, Key) -> Bool
  ) {
    
    var previousValue: Key?
    
    self._isEqual = { input in
      
      let key = selector(input)
      defer {
        previousValue = key
      }
      if let previousValue = previousValue {
        return equals(previousValue, key)
      } else {
        return false
      }
      
    }
    
  }
  
  public func isEqual(value: Input) -> Bool {
    _isEqual(value)
  }
  
  public func registerFirstValue(_ value: Input) {
    _ = _isEqual(value)
  }
  
}

extension EqualityComputer {
  public convenience init<Key: Equatable>(selector: @escaping (Input) -> Key) {
    self.init(selector: selector, equals: ==)
  }
}

extension EqualityComputer where Input : Equatable {
    
  public convenience init() {
    self.init(selector: { $0 }, equals: ==)
  }
}
