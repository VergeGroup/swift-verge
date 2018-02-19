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

public protocol CycleLogging : MutableStorageLogging {

  func didEmit(activity: Any, file: StaticString, function: StaticString, line: UInt, on cycler: AnyCyclerType)
  func willDispatch(name: String, description: String, file: StaticString, function: StaticString, line: UInt, on cycler: AnyCyclerType)
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

private var _associated: Void?

extension CyclerType {

  private var associated: Associate<Activity> {
    if let associated = objc_getAssociatedObject(self, &_associated) as? Associate<Activity> {
      return associated
    } else {
      let associated = Associate<Activity>()
      objc_setAssociatedObject(self, &_associated, associated, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return associated
    }
  }

  private var logger: CycleLogging {
    return associated.logger ?? EmptyCyclerLogger.init()
  }

  public func set(logger: CycleLogging) {
    associated.logger = logger
    state.asMutableStateStorage().loggers = [logger]
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
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line,
    _ mutate: (MutableStorage<State>) throws -> Void
    ) rethrows {

    lock.lock()

    defer {
      logger.didMutate(name: name, description: description, file: file, function: function, line: line, on: self)
      lock.unlock()
    }

    logger.willMutate(name: name, description: description, file: file, function: function, line: line, on: self)

    let mstorage = state.asMutableStateStorage()
    try mutate(mstorage)
  }

  public func dispatch<T>(
    _ name: String = "",
    _ description: String = "",
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line,
    _ action: (CyclerWeakContext<Self>) throws -> T
    ) rethrows -> T {

    lock.lock()
    defer {
      lock.unlock()
    }

    logger.willDispatch(name: name, description: description, file: file, function: function, line: line, on: self)

    return try action(.init(source: self))
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
    target: WritableKeyPath<State, S>,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
    ) -> Binder<S> {

    return Binder<S>(self) { t, e in
      t.commit(
        name,
        description,
        file: file,
        function: function,
        line: line
      ) { s in
        s.update(e, target)
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
      t.commit(
        name,
        description,
        file: file,
        function: function,
        line: line
      ) { s in
        s.update(e, target)
      }
    }
  }

  public func commitIfChangedBinder<S>(
    name: String = "",
    description: String = "",
    target: WritableKeyPath<State, S>,
    comparer: @escaping ((S, S) -> Bool),
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
    ) -> Binder<S> {

    return Binder<S>(self) { t, e in
      t.commit(
        name,
        description,
        file: file,
        function: function,
        line: line
      ) { s in
        s.updateIfChanged(e, target, comparer: comparer)
      }
    }
  }

  public func commitIfChangedBinder<S>(
    name: String = "",
    description: String = "",
    target: WritableKeyPath<State, S?>,
    comparer: @escaping ((S?, S?) -> Bool),
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
    ) -> Binder<S?> {

    return Binder<S?>(self) { t, e in
      t.commit(
        name,
        description,
        file: file,
        function: function,
        line: line
      ) { s in
        s.updateIfChanged(e, target, comparer: comparer)
      }
    }
  }

  public func commitIfChangedBinder<S: Equatable>(
    name: String = "",
    description: String = "",
    target: WritableKeyPath<State, S>,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
    ) -> Binder<S> {

    return Binder<S>(self) { t, e in
      t.commit(
        name,
        description,
        file: file,
        function: function,
        line: line
      ) { s in
        s.updateIfChanged(e, target, comparer: ==)
      }
    }
  }

  public func commitIfChangedBinder<S: Equatable>(
    name: String = "",
    description: String = "",
    target: WritableKeyPath<State, S?>,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
    ) -> Binder<S?> {

    return Binder<S?>(self) { t, e in
      t.commit(
        name,
        description,
        file: file,
        function: function,
        line: line
      ) { s in
        s.updateIfChanged(e, target, comparer: ==)
      }
    }
  }

}

public struct CyclerWeakContext<T : CyclerType> {

  weak var source: T?

  public var currentState: T.State? {
    return source?.state.value
  }

  init(source: T) {
    self.source = source
  }

  public func retain(_ retainedContext: (CyclerContext<T>) -> Void) {
    guard let source = self.source else { return }
    retainedContext(.init(source: source))
  }

  public func retained() -> CyclerContext<T>? {
    guard let source = self.source else { return nil }
    return .init(source: source)
  }

  public func emit(
    _ activity: T.Activity,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
    ) {
    source?.emit(activity, file: file, function: function, line: line)
  }

  public func commit(
    _ name: String = "",
    _ description: String = "",
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line,
    _ mutate: (MutableStorage<T.State>) throws -> Void
    ) rethrows {

    try source?.commit(name, description, file: file, function: function, line: line, mutate)
  }
}

public struct CyclerContext<T : CyclerType> {

  private let source: T

  public var currentState: T.State {
    return source.state.value
  }

  init(source: T) {
    self.source = source
  }

  public func commit(
    _ name: String = "",
    _ description: String = "",
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line,
    _ mutate: (MutableStorage<T.State>) throws -> Void
    ) rethrows {

    try source.commit(name, description, file: file, function: function, line: line, mutate)
  }

  public func emit(
    _ activity: T.Activity,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
    ) {
    source.emit(activity, file: file, function: function, line: line)
  }
}

final class Associate<Activity> {

  let lock: NSRecursiveLock = .init()

  var logger: CycleLogging?

  let activity: PublishRelay<Activity> = .init()

  init() {

  }
}
