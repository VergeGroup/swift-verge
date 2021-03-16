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
#endif

/// Describes queue to dispatch event
/// Currently light-weight impl
public final class TargetQueue {

  private let schedule: (@escaping () -> Void) -> Void

  fileprivate init(
    schedule: @escaping (@escaping () -> Void) -> Void
  ) {
    self.schedule = schedule
  }

  func serialExecutor() -> (@escaping () -> Void) -> Void {
    schedule
  }
}

fileprivate enum StaticMember {

  static let serialBackgroundDispatchQueue: DispatchQueue = .init(
    label: "org.verge.background",
    qos: .default,
    attributes: [],
    autoreleaseFrequency: .workItem,
    target: nil
  )

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

  /// Returns a instance that never dispatches.
  /// The Sink use this targetQueue performs in the queue which the upstream commit dispatched.
  public static let passthrough: TargetQueue = .init { workItem in
    workItem()
  }

  /// It dispatches to main-queue asynchronously always.
  public static let asyncMain: TargetQueue = .init { workItem in
    DispatchQueue.main.async(execute: workItem)
  }

  /// It dispatches to main-queue as possible as synchronously. Otherwise, it dispatches asynchronously from other background-thread.
  public static let main: TargetQueue = mainIsolated()

  /// It dispatches to main-queue as possible as synchronously. Otherwise, it dispatches asynchronously from other background-thread.
  /// This create isolated queue against using `.main`.
  public static func mainIsolated() -> TargetQueue {
    let numberEnqueued = VergeConcurrency.AtomicInt(initialValue: 0)

    return .init { workItem in

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

  /// Use specified queue, always dispatches
  public static func specific(_ targetQueue: DispatchQueue) -> TargetQueue {
    return .init { workItem in
      targetQueue.async(execute: workItem)
    }
  }

  /// It dispatches to the serial background queue asynchronously.
  public static var asyncSerialBackground: TargetQueue = .init { workItem in
    StaticMember.serialBackgroundDispatchQueue.async(execute: workItem)
  }

  /// Enqueue first item on current-thread(synchronously).
  /// From then, using specified queue.
  public static func startsFromCurrentThread(andUse queue: TargetQueue) -> TargetQueue {

    let numberEnqueued = VergeConcurrency.AtomicReference.init(initialValue: false)

    return .init { workItem in

      let isFirst = numberEnqueued.compareAndSet(expect: false, newValue: true)

      if isFirst {
        workItem()
      } else {
        queue.schedule(workItem)
      }
    }
  }
}


