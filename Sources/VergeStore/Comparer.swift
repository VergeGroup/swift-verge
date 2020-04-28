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
import os.log

public struct Comparer<Input> {
  
  public static var alwaysFalse: Self {
    .init { _, _ in false }
  }
  
  private let _equals: (Input, Input) -> Bool
       
  public init(
    _ equals: @escaping (Input, Input) -> Bool
  ) {
    self._equals = equals
  }
      
  /// It compares the value selected from passed selector closure
  /// - Parameter selector:
  public init<T: Equatable>(selector: @escaping (Input) -> T) {
    self.init { a, b in
      selector(a) == selector(b)
    }
  }
  
  public init<T>(selector: @escaping (Input) -> T, equals: @escaping (T, T) -> Bool) {
    self.init { a, b in
      equals(selector(a), selector(b))
    }
  }
    
  public init<T>(selector: @escaping (Input) -> T, comparer: Comparer<T>) {
    self.init { a, b in
      comparer._equals(selector(a), selector(b))
    }
  }
        
  /// Make Combined comparer
  /// - Parameter comparers:
  public init(and comparers: [Comparer<Input>]) {
    self.init { pre, new in
      for filter in comparers {
        guard filter._equals(pre, new) else {
          return false
        }
      }
      return true
    }
  }
  
  /// Make Combined comparer
  /// - Parameter comparers:
  public init(or comparers: [Comparer<Input>]) {
    self.init { pre, new in
      for filter in comparers {
        if filter._equals(pre, new) {
          return true
        }
      }
      return false
    }
  }
  
  public func equals(_ lhs: Input, _ rhs: Input) -> Bool {
    _equals(lhs, rhs)
  }
  
  public func curried() -> (_ lhs: Input, _ rhs: Input) -> Bool {
    _equals
  }
  
  public func handleResult(_ handler: @escaping (Input, Input, Bool) -> Void) -> Self {
    Self.init { [_equals, handler] in
      let result = _equals($0, $1)
      handler($0, $1, result)
      return result
    }
  }
  
}

extension Comparer where Input : Equatable {  
  public init() {
    self.init(==)
  }
}

extension Comparer {
  
  public func and(_ otherComparer: () -> Comparer) -> Comparer {
    .init(and: [
      self,
      otherComparer()
    ])
  }
  
  public func or(_ otherComparer: () -> Comparer) -> Comparer {
    .init(or: [
      self,
      otherComparer()
    ])
  }
  
  public func debug(name: String = "", file: StaticString = #file, line: UInt = #line) -> Self {
    .init { pre, new -> Bool in
      let result = self._equals(pre,new)
      os_log("%@", log: VergeOSLogs.debugLog, type: .default, "\(file.description):\(line):\(name) result:\(result)")
      return result
    }
  }
}
