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

public protocol HasTraces {
  var traces: [MutationTrace] { get }
}

/// A trace that indicates the mutation where comes from.
public struct MutationTrace: Encodable, Equatable {
  
  public static func == (lhs: MutationTrace, rhs: MutationTrace) -> Bool {
    lhs.createdAt == rhs.createdAt &&
      lhs.name == rhs.name &&
      lhs.file.description == rhs.file.description &&
      lhs.function.description == rhs.function.description &&
      lhs.line == rhs.line &&
      lhs.thread == rhs.thread
  }

  public let createdAt: Date = .init()
  public let name: String
  public let file: StaticString
  public let function: StaticString
  public let line: UInt
  public let thread: String

  public init(
    name: String = "",
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line,
    thread: Thread = .current
  ) {
    self.name = name
    self.file = file
    self.function = function
    self.line = line
    self.thread = thread.description
  }

}

extension StaticString: Encodable {

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(description)
  }
}
