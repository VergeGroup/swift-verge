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

public protocol StateType {
  
}

public enum StateUpdatingError: Swift.Error {
  case targetWasNull
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
  
  public mutating func updateIfValid<T: TransientType, Result, FinalResult>(
    target keyPath: WritableKeyPath<Self, T>,
    update: (inout T.State) throws -> Result,
    completion: (Result) -> FinalResult
  ) rethrows -> FinalResult? {
    
    switch self[keyPath: keyPath].box {
    case .none:
      return nil
    case .some:
      return completion(try update(&self[keyPath: keyPath].unsafelyUnwrap))
    }
  }
  
  public mutating func update<Return>(update: (inout Self) throws -> Return) rethrows -> Return {
    try update(&self)
  }
  
}
