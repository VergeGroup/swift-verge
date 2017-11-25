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

public protocol MutableStorageLogging {

  func didChange(value: Any, for keyPath: AnyKeyPath, root: Any)
  func didChange(root: Any)
  func didReplace(root: Any)
}

public protocol CycleLogging : MutableStorageLogging {

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
  public func willDispatch(name: String, description: String, file: StaticString, function: StaticString, line: UInt, on cycler: AnyCyclerType) {}
  public func willMutate(name: String, description: String, file: StaticString, function: StaticString, line: UInt, on cycler: AnyCyclerType) {}
  public func didMutate(name: String, description: String, file: StaticString, function: StaticString, line: UInt, on cycler: AnyCyclerType) {}
}

public protocol AnyCyclerType : class {

}

public protocol CyclerType : AnyCyclerType {
  associatedtype State
  var state: Storage<State> { get }
  var initialState: State { get }
}

private var _associated: Void?

extension CyclerType {

  var associated: Associate<State> {
    if let associated = objc_getAssociatedObject(self, &_associated) as? Associate<State> {
      return associated
    } else {
      let associated = Associate<State>(initialSate: initialState)
      objc_setAssociatedObject(self, &_associated, associated, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return associated
    }
  }

  var logger: CycleLogging {
    return associated.logger ?? EmptyCyclerLogger.init()
  }

  public func set(logger: CycleLogging) {
    associated.logger = logger
  }

  public var state: Storage<State> {
    return associated.state
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
    _ mutate: @escaping (MutableStorage<State>) throws -> Void
    ) rethrows {

    lock.lock()

    defer {
      logger.didMutate(name: name, description: description, file: file, function: function, line: line, on: self)
      lock.unlock()
    }

    _ = associated
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

    _ = associated
    logger.willDispatch(name: name, description: description, file: file, function: function, line: line, on: self)

    return try action(.init(source: self))
  }
}

public struct CyclerWeakContext<T : CyclerType> {

  weak var source: T?

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
}

public struct CyclerContext<T : CyclerType> {

  let source: T

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
    _ mutate: @escaping (MutableStorage<T.State>) throws -> Void
    ) rethrows {

    try source.commit(name, description, file: file, function: function, line: line, mutate)
  }
}

final class Associate<State> {

  let lock: NSRecursiveLock = .init()
  let state: Storage<State>

  var logger: CycleLogging? {
    didSet {
      if let logger = logger {
        self.state.asMutableStateStorage().loggers = [logger]
      }
    }
  }

  init(initialSate: State) {
    self.state = .init(initialSate)
  }
}

public final class Storage<T> {

  public var value: T {
    return source.value
  }

  private let source: MutableStorage<T>
  private let disposeBag: DisposeBag = .init()

  public convenience init(_ initialValue: T) {
    self.init(.init(initialValue))
  }

  public init(_ variable: MutableStorage<T>) {
    self.source = variable
  }

  public func asObservable() -> Observable<T> {
    return source.source.asObservable()
  }

  public func asObservable<S>(keyPath: KeyPath<T, S>) -> Observable<S> {
    return asObservable()
      .map { $0[keyPath: keyPath] }
  }

  public func asDriver() -> Driver<T> {
    return source.source.asDriver()
  }

  public func asDriver<S>(keyPath: KeyPath<T, S>) -> Driver<S> {
    return asDriver()
      .map { $0[keyPath: keyPath] }
  }

  public func map<U>(_ closure: @escaping (T) -> U) -> Storage<U> {

    let m_state = MutableStorage.init(closure(value))

    let state = m_state.asStorage()

    asObservable()
      .map(closure)
      .subscribe(onNext: { [weak m_state] o in
        m_state?.source.accept(o)
      })
      .disposed(by: state.disposeBag)

    return state
  }

  fileprivate func asMutableStateStorage() -> MutableStorage<T> {
    return source
  }
}

public final class MutableStorage<T> {

  public var loggers: [MutableStorageLogging] = []

  public var value: T {
    get {
      return source.value
    }
  }

  fileprivate var writableValue: T {
    get {
      return source.value
    }
    set {
      source.accept(newValue)
    }
  }

  fileprivate let source: BehaviorRelay<T>

  public init(_ value: T) {
    self.source = .init(value: value)
  }

  public func asObservable() -> Observable<T> {
    return source.asObservable()
  }

  public func asObservable<S>(keyPath: KeyPath<T, S>) -> Observable<S> {
    return asObservable()
      .map { $0[keyPath: keyPath] }
  }

  public func asDriver() -> Driver<T> {
    return source.asDriver()
  }

  public func asDriver<S>(keyPath: KeyPath<T, S>) -> Driver<S> {
    return asDriver()
      .map { $0[keyPath: keyPath] }
  }

  public func replace(_ value: T) {
    writableValue = value

    loggers.forEach { $0.didReplace(root: writableValue) }
  }

  public func update(_ execute: @escaping (inout T) throws -> Void) rethrows {
    try execute(&writableValue)

    loggers.forEach { $0.didChange(root: writableValue) }
  }

  public func update<E>(_ value: E?, _ keyPath: WritableKeyPath<T, E?>) {
    writableValue[keyPath: keyPath] = value

    loggers.forEach { $0.didChange(value: value as Any, for: keyPath, root: writableValue) }
  }

  public func update<E>(_ value: E, _ keyPath: WritableKeyPath<T, E>) {
    writableValue[keyPath: keyPath] = value

    loggers.forEach { $0.didChange(value: value as Any, for: keyPath, root: writableValue) }
  }

  public func updateIfChanged<E>(_ value: E?, _ keyPath: WritableKeyPath<T, E?>, comparer: (E?, E?) -> Bool) {
    guard comparer(writableValue[keyPath: keyPath], value) == false else { return }
    writableValue[keyPath: keyPath] = value

    loggers.forEach { $0.didChange(value: value as Any, for: keyPath, root: writableValue) }
  }

  public func updateIfChanged<E: Equatable>(_ value: E?, _ keyPath: WritableKeyPath<T, E?>, comparer: (E?, E?) -> Bool = { $0 == $1 }) {
    guard comparer(writableValue[keyPath: keyPath], value) == false else { return }
    writableValue[keyPath: keyPath] = value

    loggers.forEach { $0.didChange(value: value as Any, for: keyPath, root: writableValue) }
  }

  public func updateIfChanged<E>(_ value: E, _ keyPath: WritableKeyPath<T, E>, comparer: (E, E) -> Bool) {
    guard comparer(writableValue[keyPath: keyPath], value) == false else { return }
    writableValue[keyPath: keyPath] = value

    loggers.forEach { $0.didChange(value: value as Any, for: keyPath, root: writableValue) }
  }

  public func updateIfChanged<E : Equatable>(_ value: E, _ keyPath: WritableKeyPath<T, E>, comparer: (E, E) -> Bool = { $0 == $1 }) {
    guard comparer(writableValue[keyPath: keyPath], value) == false else { return }
    writableValue[keyPath: keyPath] = value

    loggers.forEach { $0.didChange(value: value as Any, for: keyPath, root: writableValue) }
  }

  public func asStorage() -> Storage<T> {
    return .init(self)
  }
}
