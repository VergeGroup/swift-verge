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
@_implementationOnly import Atomics

public protocol TargetQueueType: AnyObject {
  func execute(_ workItem: @escaping () -> Void)
}

/// Describes queue to dispatch event
/// Currently light-weight impl
/// A reason why class is to take an object identifier.
public final class AnyTargetQueue: TargetQueueType {

  private let _execute: (@escaping () -> Void) -> Void

  fileprivate init(
    _execute: @escaping (@escaping () -> Void) -> Void
  ) {
    self._execute = _execute
  }

  public func execute(_ workItem: @escaping () -> Void) {
    _execute(workItem)
  }

}

public final class MainActorTargetQueue: TargetQueueType {

  private let _execute: (@escaping () -> Void) -> Void

  fileprivate init(
    _execute: @escaping (@escaping () -> Void) -> Void
  ) {
    self._execute = _execute
  }

  public func execute(_ workItem: @escaping () -> Void) {
    _execute(workItem)
  }

}

private enum StaticMember {

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

extension TargetQueueType where Self == AnyTargetQueue {
  /// Returns a instance that never dispatches.
  /// The Sink use this targetQueue performs in the queue which the upstream commit dispatched.
  public static var passthrough: AnyTargetQueue {
    AnyTargetQueue._passthrough
  }

  /// Use specified queue, always dispatches
  public static func specific(_ targetQueue: DispatchQueue) -> AnyTargetQueue {
    return .init { workItem in
      targetQueue.async(execute: workItem)
    }
  }
  /// It dispatches to the serial background queue asynchronously.
  public static var asyncSerialBackground: AnyTargetQueue {
    AnyTargetQueue._asyncSerialBackground
  }

  /// Enqueue first item on current-thread(synchronously).
  /// From then, using specified queue.
  public static func startsFromCurrentThread<Queue: TargetQueueType>(andUse queue: Queue) -> AnyTargetQueue {
    let numberEnqueued = ManagedAtomic<Bool>.init(true)
    
    let execute = queue.execute
    
    return .init { workItem in
      
      let isFirst = numberEnqueued.loadThenLogicalAnd(with: false, ordering: .relaxed)
      
      if isFirst {
        workItem()
      } else {
        execute(workItem)
      }
      
    }
  }
}

extension TargetQueueType where Self == MainActorTargetQueue {

  /// It dispatches to main-queue asynchronously always.
  public static var asyncMain: MainActorTargetQueue {
    MainActorTargetQueue._asyncMain
  }

  /// It dispatches to main-queue as possible as synchronously. Otherwise, it dispatches asynchronously from other background-thread.
  public static var main: MainActorTargetQueue {
    MainActorTargetQueue._main
  }

  /// It dispatches to main-queue as possible as synchronously. Otherwise, it dispatches asynchronously from other background-thread.
  /// This create isolated queue against using `.main`.
  public static func mainIsolated() -> MainActorTargetQueue {
    let numberEnqueued = ManagedAtomic<UInt64>.init(0)
    
    return .init { workItem in
      
      let previousNumberEnqueued = numberEnqueued.loadThenWrappingIncrement(ordering: .sequentiallyConsistent)
      
      if DispatchQueue.isMain && previousNumberEnqueued == 0 {
        workItem()
        numberEnqueued.wrappingDecrement(ordering: .sequentiallyConsistent)
      } else {
        DispatchQueue.main.async {
          workItem()
          numberEnqueued.wrappingDecrement(ordering: .sequentiallyConsistent)
        }
      }
    }
  }
}

extension MainActorTargetQueue {
  /// It dispatches to main-queue asynchronously always.
  static let _asyncMain: MainActorTargetQueue = .init { workItem in
    DispatchQueue.main.async(execute: workItem)
  }

  /// It dispatches to main-queue as possible as synchronously. Otherwise, it dispatches asynchronously from other background-thread.
  static let _main: MainActorTargetQueue = mainIsolated()

}

extension AnyTargetQueue {

  /// Returns a instance that never dispatches.
  /// The Sink use this targetQueue performs in the queue which the upstream commit dispatched.
  static let _passthrough: AnyTargetQueue = .init { workItem in
    workItem()
  }

  /// It dispatches to the serial background queue asynchronously.
  static let _asyncSerialBackground: AnyTargetQueue = .init { workItem in
    StaticMember.serialBackgroundDispatchQueue.async(execute: workItem)
  }

}
