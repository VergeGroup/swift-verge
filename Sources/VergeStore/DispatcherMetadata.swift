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

public struct DispatcherMetadata: Encodable {
  
  private let backing: ActionContainer?
  
  public var fromActionMetadata: ActionMetadata? {
    backing?.fromAction
  }
  
  public func encode(to encoder: Encoder) throws {
    try fromActionMetadata.encode(to: encoder)
  }
  
  init(fromAction: ActionMetadata?) {
    self.backing = fromAction.map { ._backing($0) }
  }
  
  indirect enum ActionContainer {
    
    public var fromAction: ActionMetadata {
      switch self {
      case ._backing(let m): return m
      }
    }
    
    case _backing(ActionMetadata)
    
    init(fromAction: ActionMetadata) {
      self = ._backing(fromAction)
    }
    
  }
    
}


