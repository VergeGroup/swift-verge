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
import StateStruct

/**
 An opt-in protocol that indicates it's used as a state of the State.
 */
public protocol StateType: Equatable, TrackingObject {

  /**
   A chance of modifying state alongside the commit.
   You may use this to make another value that consists of the state's self.
   It's better to use it for better performance to get the value rather than using computed property.
   */
  @Sendable
  static func reduce(
    modifying: inout Self,
    transaction: inout Transaction,
    current: Changes<Self>
  )
}

extension StateType {

  /**
   Default empty implementation
   */
  @Sendable
  public static func reduce(
    modifying: inout Self,
    transaction: inout Transaction,
    current: Changes<Self>
  )

  }
}
