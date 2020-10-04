//
//  Deprecated.swift
//  VergeStore
//
//  Created by muukii on 2020/10/04.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

extension Store {


  /// Subscribe the state changes
  ///
  /// First object always returns true from ifChanged / hasChanges / noChanges unless dropsFirst is true.
  ///
  /// - Parameters:
  ///   - dropsFirst: Drops the latest value on started. if true, receive closure will call from next state updated.
  ///   - queue: Specify a queue to receive changes object.
  /// - Returns: A subscriber that performs the provided closure upon receiving values.
  @available(*, deprecated, renamed: "sinkState(dropsFirst:scheduler:receive:)")
  @_disfavoredOverload
  public func sinkState(
    dropsFirst: Bool = false,
    queue: Scheduler = .asyncMain,
    receive: @escaping (Changes<State>) -> Void
  ) -> VergeAnyCancellable {

    sinkState(dropsFirst: dropsFirst, scheduler: queue, receive: receive)

  }

  /// Subscribe the state changes
  ///
  /// First object always returns true from ifChanged / hasChanges / noChanges unless dropsFirst is true.
  ///
  /// - Parameters:
  ///   - scan: Accumulates a specified type of value over receiving updates.
  ///   - dropsFirst: Drops the latest value on started. if true, receive closure will call from next state updated.
  ///   - queue: Specify a queue to receive changes object.
  /// - Returns: A subscriber that performs the provided closure upon receiving values.
  @available(*, deprecated, renamed: "sinkState(scan:dropsFirst:scheduler:receive:)")
  @_disfavoredOverload
  public func sinkState<Accumulate>(
    scan: Scan<Changes<State>, Accumulate>,
    dropsFirst: Bool = false,
    queue: Scheduler = .asyncMain,
    receive: @escaping (Changes<State>, Accumulate) -> Void
  ) -> VergeAnyCancellable {

    sinkState(scan: scan, dropsFirst: dropsFirst, scheduler: queue, receive: receive)

  }

  /// Subscribe the activity
  ///
  /// - Returns: A subscriber that performs the provided closure upon receiving values.
  @available(*, deprecated, renamed: "sinkActivity(scheduler:receive:)")
  @_disfavoredOverload
  public func sinkActivity(
    queue: Scheduler = .asyncMain,
    receive: @escaping (Activity) -> Void
  ) -> VergeAnyCancellable {
    sinkActivity(scheduler: queue, receive: receive)
  }

  /// Subscribe the activity
  ///
  /// - Returns: A subscriber that performs the provided closure upon receiving values.
  public func sinkActivity(
    scheduler: Scheduler = .asyncMain,
    receive: @escaping (Activity) -> Void
  ) -> VergeAnyCancellable {

    let execute = scheduler.executor()
    let cancellable = _activityEmitter.add { (activity) in
      execute {
        receive(activity)
      }
    }
    return .init(cancellable)

  }


}
