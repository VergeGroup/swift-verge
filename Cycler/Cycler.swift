//
// Cycler
//
// Copyright (c) 2017 muukii
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
//
//  ViewModel.swift
//  RxExtension
//
//  Created by muukii on 9/5/17.
//  Copyright © 2017 eure. All rights reserved.
//

import Foundation
import ObjectiveC

import RxSwift
import RxCocoa

public enum NoActivity {}
public struct NoState {}

public protocol CycleLogging : MutableStorageLogging {

  func didEmit(activity: Any, file: StaticString, function: StaticString, line: UInt, on cycler: AnyCyclerType)
  func willDispatch(name: String, description: String, file: StaticString, function: StaticString, line: UInt, on cycler: AnyCyclerType)
  func didDispatch(name: String, description: String, file: StaticString, function: StaticString, line: UInt, result: DispatchResult, on cycler: AnyCyclerType)
  func willMutate(name: String, description: String, file: StaticString, function: StaticString, line: UInt, on cycler: AnyCyclerType)
  func didMutate(name: String, description: String, file: StaticString, function: StaticString, line: UInt, on cycler: AnyCyclerType)
}

extension CycleLogging {
  static func empty() -> EmptyCyclerLogger {
    return .init()
  }
}

public struct EmptyCyclerLogger : CycleLogging {

  public init() {}

  public func didChange(value: Any, for keyPath: AnyKeyPath, root: Any) {}
  public func didChange(root: Any) {}
  public func didReplace(root: Any) {}
  public func didEmit(activity: Any, file: StaticString, function: StaticString, line: UInt, on: AnyCyclerType) {}
  public func willDispatch(name: String, description: String, file: StaticString, function: StaticString, line: UInt, on cycler: AnyCyclerType) {}
  public func didDispatch(name: String, description: String, file: StaticString, function: StaticString, line: UInt, result: DispatchResult, on cycler: AnyCyclerType) {}
  public func willMutate(name: String, description: String, file: StaticString, function: StaticString, line: UInt, on cycler: AnyCyclerType) {}
  public func didMutate(name: String, description: String, file: StaticString, function: StaticString, line: UInt, on cycler: AnyCyclerType) {}
}

public protocol AnyCyclerType : class {

}

/// The protocol is core of Cycler
public protocol CyclerType : AnyCyclerType {
  associatedtype State
  associatedtype Activity
  var state: Storage<State> { get }
}

public protocol ModularCyclerType : CyclerType {
  associatedtype Parent : CyclerType
}

private var _associated: Void?
private var _modularAssociated: Void?

public final class DeinitBox {

  private let onDeinit: () -> Void

  init<T>(_ value: T, _ onDeinit: @escaping (T) -> Void) {
    self.onDeinit = {
      onDeinit(value)
    }
  }

  deinit {
    onDeinit()
  }
}

public enum DispatchResult {
  case success
  case error(Error)
}

extension CyclerType {

  private var associated: CyclerAssociated<Activity> {
    if let associated = objc_getAssociatedObject(self, &_associated) as? CyclerAssociated<Activity> {
      return associated
    } else {
      let associated = CyclerAssociated<Activity>()
      objc_setAssociatedObject(self, &_associated, associated, .OBJC_ASSOCIATION_RETAIN)
      return associated
    }
  }

  func append(deinitBox: DeinitBox) {
    lock.lock(); defer { lock.unlock() }
    associated.deinitBoxes.append(deinitBox)
  }

  private var logger: CycleLogging {
    return associated.logger ?? EmptyCyclerLogger.init()
  }

  public func set(logger: CycleLogging) {
    lock.lock(); defer { lock.unlock() }
    associated.logger = logger
    state.mutableStateStorage.loggers = [logger]
  }

  public var activity: Signal<Activity> {
    return associated.activity.asSignal()
  }

  public var lock: NSRecursiveLock {
    return associated.lock
  }

  public func commit(
    _ name: String = "",
    _ description: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ mutate: (inout State) throws -> Void
    ) rethrows {

    lock.lock()

    defer {
      logger.didMutate(name: name, description: description, file: file, function: function, line: line, on: self)
      lock.unlock()
    }

    logger.willMutate(name: name, description: description, file: file, function: function, line: line, on: self)

    try state.mutableStateStorage.update(mutate)
  }

  public func commit(
    _ name: String = "",
    _ description: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    replace newState: State
    ) {

    lock.lock()

    defer {
      logger.didMutate(name: name, description: description, file: file, function: function, line: line, on: self)
      lock.unlock()
    }

    logger.willMutate(name: name, description: description, file: file, function: function, line: line, on: self)

    state.mutableStateStorage.replace(newState)
  }

  @discardableResult
  public func dispatch<T>(
    _ name: String = "",
    _ description: String = "",
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line,
    _ action: (DispatchContext<Self>) throws -> T
    ) rethrows -> T {

    lock.lock(); defer { lock.unlock() }

    logger.willDispatch(
      name: name,
      description: description,
      file: file,
      function: function,
      line: line,
      on: self
    )

    return try action(
      .init(
        actionName: name,
        source: self,
        completion: { [weak self] result in
          guard let `self` = self else { return }
          self.logger.didDispatch(
            name: name,
            description: description,
            file: file,
            function: function,
            line: line,
            result: result,
            on: self
          )
      })
    )
  }

  fileprivate func emit(
    _ activity: Activity,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
    ) {

    associated.activity.accept(activity)
    logger.didEmit(activity: activity, file: file, function: function, line: line, on: self)
  }
}

extension CyclerType {

  public func commitBinder<S>(
    name: String = "",
    description: String = "",
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line,
    mutate: @escaping (inout State, S) -> Void
    ) -> Binder<S> {

    return Binder<S>(self) { t, e in
      t.commit { s in
        mutate(&s, e)
      }
    }
  }

  public func commitBinder<S>(
    name: String = "",
    description: String = "",
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line,
    mutate: @escaping (inout State, S?) -> Void
    ) -> Binder<S?> {

    return Binder<S?>(self) { t, e in
      t.commit { s in
        mutate(&s, e)
      }
    }
  }

  public func commitBinder<S>(
    name: String = "",
    description: String = "",
    target: WritableKeyPath<State, S>,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
    ) -> Binder<S> {

    return Binder<S>(self) { t, e in
      t.commit { s in
        s[keyPath: target] = e
      }
    }
  }

  public func commitBinder<S>(
    name: String = "",
    description: String = "",
    target: WritableKeyPath<State, S?>,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
    ) -> Binder<S?> {

    return Binder<S?>(self) { t, e in
      t.commit { s in
        s[keyPath: target] = e
      }
    }
  }
}

extension ModularCyclerType {

  fileprivate var modularAssociated: ModularCyclerAssociated<Parent> {
    if let associated = objc_getAssociatedObject(self, &_modularAssociated) as? ModularCyclerAssociated<Parent> {
      return associated
    } else {
      let associated = ModularCyclerAssociated<Parent>()
      objc_setAssociatedObject(self, &_modularAssociated, associated, .OBJC_ASSOCIATION_RETAIN)
      return associated
    }
  }

  public func forward(_ c: (_ parent: Parent) -> Void) {
    guard let parent = modularAssociated.parent ?? modularAssociated.retainedParent else {
      assertionFailure("\(String(describing: self)) is not set parent. `should call set(parent: Parent)`")
      return
    }
    c(parent)
  }

  public func set(parent: Parent, retain: Bool = false) {
    if retain {
      modularAssociated.retainedParent = parent
    } else {
      modularAssociated.parent = parent
    }
  }
}

public final class DispatchContext<T : CyclerType> {

  private weak var source: T?
  private let state: Storage<T.State>
  private let completion: (DispatchResult) -> Void
  private let lock: NSLock = .init()
  private let actionName: String
  private var isCompleted: Bool = false

  public var currentState: T.State {
    return state.value
  }

  init(actionName: String, source: T, completion: @escaping (DispatchResult) -> Void) {
    self.source = source
    self.state = source.state
    self.completion = completion
    self.actionName = actionName
  }

  deinit {
    #if DEBUG
    if isCompleted == false {
      print("DispatchContext is released without completion")
    }
    #endif
  }

  public func commit(
    _ name: String = "",
    _ description: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ mutate: (inout T.State) throws -> Void
    ) rethrows {

    precondition(isCompleted == false, "Context has already been completed.")
    try source?.commit(name, description, file, function, line, mutate)
  }

  public func emit(
    _ activity: T.Activity,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
    ) {
    precondition(isCompleted == false, "Context has already been completed.")
    source?.emit(activity, file: file, function: function, line: line)
  }

  public func complete(_ result: DispatchResult) {
    lock.lock(); defer { lock.unlock() }
    precondition(isCompleted == false, "Context has already been completed.")
    isCompleted = true
    completion(result)
  }

  func retainUntilDeinitCycler(box: DeinitBox) {
    source?.append(deinitBox: box)
  }
}

final class CyclerAssociated<Activity> {

  let lock: NSRecursiveLock = .init()

  var logger: CycleLogging?

  let activity: PublishRelay<Activity> = .init()

  var deinitBoxes: [DeinitBox] = []

  init() {

  }
}

final class ModularCyclerAssociated<Cycler : CyclerType> {

  weak var parent: Cycler?

  var retainedParent: Cycler?

  init() {

  }
}

extension PrimitiveSequence where Trait == SingleTrait {

  /// Subscribe observable by Cycler, and return shared observable
  ///
  /// - Parameters:
  ///   - context:
  ///   - untilDeinit:
  /// - Returns: Shared observable.
  @discardableResult
  public func subscribe<C>(with context: DispatchContext<C>, untilDeinit: Bool = true) -> Single<Element> {

    let source = self.asObservable()
      .share(replay: 1, scope: .whileConnected)
      .asSingle()

    let subscription = source
      .do(onNext: { _ in
        context.complete(.success)
      }, onError: { error in
        context.complete(.error(error))
      })
      .subscribe()

    if untilDeinit {
      context.retainUntilDeinitCycler(box: .init(subscription, { $0.dispose() }))
    }

    return source
  }
}

extension PrimitiveSequence where Trait == MaybeTrait {

  /// Subscribe observable by Cycler, and return shared observable
  ///
  /// - Parameters:
  ///   - context:
  ///   - untilDeinit:
  /// - Returns: Shared observable.
  @discardableResult
  public func subscribe<C>(with context: DispatchContext<C>, untilDeinit: Bool = true) -> Maybe<Element> {

    let source = self.asObservable()
      .share(replay: 1, scope: .whileConnected)
      .asMaybe()

    let subscription = source
      .do(onNext: { _ in
        context.complete(.success)
      }, onError: { error in
        context.complete(.error(error))
      })
      .subscribe()

    if untilDeinit {
      context.retainUntilDeinitCycler(box: .init(subscription, { $0.dispose() }))
    }

    return source
  }
}
