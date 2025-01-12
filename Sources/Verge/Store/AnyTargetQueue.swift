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
import Atomics

public protocol TargetQueueType {
  func execute(_ workItem: sending @escaping @Sendable () -> Void)
}

/// Describes queue to dispatch event
/// Currently light-weight impl
/// A reason why class is to take an object identifier.
public final class AnyTargetQueue: TargetQueueType {

  private let _execute: (@escaping @Sendable () -> Void) -> Void

  fileprivate init(
    _execute: @escaping (@escaping @Sendable () -> Void) -> Void
  ) {
    self._execute = _execute
  }

  public func execute(_ workItem: @escaping @Sendable () -> Void) {
    _execute(workItem)
  }

}

public protocol MainActorTargetQueueType {
  func execute(_ workItem: @escaping @MainActor () -> Void)
}

extension MainActorTargetQueueType where Self == ImmediateMainActorTargetQueue {
  public static func mainIsolated() -> Self {
    .init()
  }
  
  public static var main: Self {
    .shared
  }
  
}

extension MainActorTargetQueueType where Self == HoppingMainActorTargetQueue {
  
  /// It dispatches to main-queue asynchronously always.
  public static var asyncMain: Self {
    return .init()
  }
}

/// always dispatches to main-queue asynchronously
public struct HoppingMainActorTargetQueue: MainActorTargetQueueType {

  init() {
  }

  public func execute(_ workItem: @escaping @MainActor () -> Void) {
 
    DispatchQueue.main.async {
      workItem()
    }
  }

}

/// It dispatches to main-queue as possible as synchronously. Otherwise, it dispatches asynchronously.
public struct ImmediateMainActorTargetQueue: Sendable, MainActorTargetQueueType {
  
  public static let shared = Self()

  private let numberEnqueued = ManagedAtomic<UInt64>.init(0)
  
  init() {

  }
  
  public func execute(_ workItem: @escaping @MainActor () -> Void) {
          
    let previousNumberEnqueued = numberEnqueued.loadThenWrappingIncrement(ordering: .sequentiallyConsistent)
    
    if Thread.isMainThread && previousNumberEnqueued == 0 {
      MainActor.assumeIsolated {
        workItem()
      }
      numberEnqueued.wrappingDecrement(ordering: .sequentiallyConsistent)
    } else {
      DispatchQueue.main.async {
        workItem()
        self.numberEnqueued.wrappingDecrement(ordering: .sequentiallyConsistent)
      }
    }
    
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

extension TargetQueueType where Self == Queues.Passthrough  {

  /// Returns a instance that never dispatches.
  /// The Sink use this targetQueue performs in the queue which the upstream commit dispatched.
  public static var passthrough: Queues.Passthrough {
    .init()
  }

}

extension TargetQueueType where Self == Queues.AsyncBackground {
  /// It dispatches to the serial background queue asynchronously.
  public static var asyncSerialBackground: Self {
    self.init()
  }
}

extension TargetQueueType where Self == AnyTargetQueue {


  /// Use specified queue, always dispatches
  public static func specific(_ targetQueue: DispatchQueue) -> AnyTargetQueue {
    return .init { workItem in
      targetQueue.async(execute: workItem)
    }
  }


  /// Enqueue first item on current-thread(synchronously).
  /// From then, using specified queue.
  public static func startsFromCurrentThread(andUse queue: some TargetQueueType) -> AnyTargetQueue {
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

  /// Enqueue first item on current-thread(synchronously).
  /// From then, using specified queue.
  public static func startsFromCurrentThread(andUse queue: some MainActorTargetQueueType) -> AnyTargetQueue {
    return startsFromCurrentThread(andUse: Queues.MainActor(queue))
  }

}

extension HoppingMainActorTargetQueue {

  /// It dispatches to main-queue asynchronously always.
  public static var asyncMain: HoppingMainActorTargetQueue {
    return .init()
  }

  /// It dispatches to main-queue as possible as synchronously. Otherwise, it dispatches asynchronously from other background-thread.
  public static var main: ImmediateMainActorTargetQueue {
    return .shared
  }

  /// It dispatches to main-queue as possible as synchronously. Otherwise, it dispatches asynchronously from other background-thread.
  /// This create isolated queue against using `.main`.
  public static func mainIsolated() -> ImmediateMainActorTargetQueue {
    return .init()
  }
}

public enum Queues {

  struct MainActor<Underlying: MainActorTargetQueueType>: TargetQueueType {

    let underlying: Underlying

    init(_ underlying: Underlying) {
      self.underlying = underlying
    }

    public func execute(_ workItem: sending @escaping @Sendable () -> Void) {
      underlying.execute(workItem)
    }

  }

  public struct Passthrough: TargetQueueType {

    public func execute(_ workItem: sending @escaping @Sendable () -> Void) {
      workItem()
    }

  }

  public struct AsyncBackground: TargetQueueType {

    private let executor: BackgroundActor = .init()

    public func execute(_ workItem: sending @escaping @Sendable () -> Void) {
      Task { [executor, workItem] in
        await executor.perform(workItem)
      }
    }
    
    private actor BackgroundActor: Actor {

      init() {

      }
          
      func perform<R>(_ operation: sending @Sendable () throws -> R) rethrows -> R {
        try operation()
      }
          
    }

  }

}
