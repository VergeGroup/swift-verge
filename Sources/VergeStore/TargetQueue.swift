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

#if !COCOAPODS
import VergeCore
#endif

/// Describes queue to dispatch event
/// Currently light-weight impl
public final class TargetQueue {

  /// An identifier to be used cache internally.
  public let identifier: String

  private let dispatch: (@escaping () -> Void) -> Void

  fileprivate init(
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

  static let passthrough: TargetQueue = .init(identifier: "passthrough") { workItem in
    workItem()
  }

  static let asyncMain: TargetQueue = .init(identifier: "async-main") { workItem in
    DispatchQueue.main.async(execute: workItem)
  }

  static let serialBackgroundDispatchQueue: DispatchQueue = .init(label: "org.verge.background", qos: .default, attributes: [], autoreleaseFrequency: .workItem, target: nil)

  static let serialBackground: TargetQueue = .init(identifier: "asyncSerialBackground") { workItem in
    serialBackgroundDispatchQueue.async(execute: workItem)
  }

}

extension DispatchQueue {
  private static var token: DispatchSpecificKey<()> = {
    let key = DispatchSpecificKey<()>()
    DispatchQueue.main.setSpecific(key: key, value: ())
    return key
  }()

  static var isMain: Bool {
    return DispatchQueue.getSpecific(key: token) != nil
  }
}


extension TargetQueue {

  /// It never dispatches.
  public static var passthrough: TargetQueue {
    TargetQueue_StaticMember.passthrough
  }

  /// It dispatches to main-queue as possible as synchronously. Otherwise, it dispatches asynchronously from other background-thread.
  public static func main() -> TargetQueue {

    let numberEnqueued = VergeConcurrency.AtomicInt(initialValue: 0)

    return .init(identifier: "main-\(UUID().uuidString)") { workItem in

      let previousNumberEnqueued = numberEnqueued.getAndIncrement()

      if DispatchQueue.isMain && previousNumberEnqueued == 0 {
        workItem()
        numberEnqueued.decrementAndGet()
      } else {
        DispatchQueue.main.async {
          workItem()
          numberEnqueued.decrementAndGet()
        }
      }
    }
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
