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

public struct Comparer<Input> {
  
  private let equals: (Input, Input) -> Bool
    
  public init(_ equals: @escaping (Input, Input) -> Bool) {
    self.equals = equals
  }
    
  /// It compares the value selected from passed selector closure
  /// - Parameter selector:
  public init<T: Equatable>(selector: @escaping (Input) -> T) {
    self.equals = { a, b in
      selector(a) == selector(b)
    }
  }
    
  /// Make Combined comparer
  /// - Parameter comparers:
  public init(and comparers: [Comparer<Input>]) {
    self.equals = { pre, new in
      for filter in comparers {
        guard filter.equals(previousValue: pre, newValue: new) else {
          return false
        }
      }
      return true
    }
  }
  
  /// Make Combined comparer
  /// - Parameter comparers:
  public init(or comparers: [Comparer<Input>]) {
    self.equals = { pre, new in
      for filter in comparers {
        if filter.equals(previousValue: pre, newValue: new) {
          return true
        }
      }
      return false
    }
  }
  
  public func equals(previousValue: Input, newValue: Input) -> Bool {
    equals(previousValue, newValue)
  }
  
}

