//
// Copyright (c) 2020 Hiroshi Kimura(Muukii) <muukii.app@gmail.com>
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

/// Describes queue to dispatch event
/// Currently light-weight impl
public struct TargetQueue {

  /// An identifier to be used cache internally.
  public let identifier: String

  private let dispatch: (@escaping () -> Void) -> Void

  public init(
    identifier: String,
    dispatch: @escaping (@escaping () -> Void) -> Void
  ) {
    self.identifier = identifier
    self.dispatch = dispatch
  }

  func executor() -> (@escaping () -> Void) -> Void {
    dispatch
  }
}

fileprivate enum TargetQueue_StaticMember {

  static let main: TargetQueue = .init(identifier: "main") { workItem in
    if Thread.isMainThread {
      workItem()
    } else {
      DispatchQueue.main.async(execute: workItem)
    }
  }

  static let asyncMain: TargetQueue = .init(identifier: "async-main") { workItem in
    DispatchQueue.main.async(execute: workItem)
  }

  static let serialBackgroundDispatchQueue: DispatchQueue = .init(label: "org.verge.background", qos: .default, attributes: [], autoreleaseFrequency: .workItem, target: nil)

  static let serialBackground: TargetQueue = .init(identifier: "asyncSerialBackground") { workItem in
    serialBackgroundDispatchQueue.async(execute: workItem)
  }

}

extension TargetQueue {

  /// It dispatches to main-queue as possible as synchronously. Otherwise, it dispatches asynchronously from other background-thread.
  public static var main: TargetQueue {
    TargetQueue_StaticMember.main
  }

  /// It dispatches to main-queue asynchronously always.
  public static var asyncMain: TargetQueue {
    TargetQueue_StaticMember.asyncMain
  }

  /// Use specified queue, always dispatches
  public static func specific(_ targetQueue: DispatchQueue) -> TargetQueue {
    return .init(identifier: "queue-\(ObjectIdentifier(targetQueue))") { workItem in
      targetQueue.async(execute: workItem)
    }
  }

  /// It dispatches to the serial background queue asynchronously.
  public static var asyncSerialBackground: TargetQueue {
    TargetQueue_StaticMember.serialBackground
  }
}
