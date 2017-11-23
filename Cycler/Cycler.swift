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

public struct NoState {}
public struct NoActivity {}
public struct NoAction {}

public struct AnyMutation<State> {

  public let name: String
  public let mutate: (MutableStorage<State>) throws -> Void

  public init(_ name: String, _ mutate: @escaping (MutableStorage<State>) throws -> Void) {
    self.name = name
    self.mutate = mutate
  }
}

public protocol CyclerCoreType : class {

  associatedtype State
  associatedtype Mutation

  var state: Storage<State> { get }
  func commit(_ mutation: Mutation)
}

public protocol CyclerType : CyclerCoreType {

  associatedtype Activity

  var activity: Signal<Activity> { get }
  func receiveError(error: Error)
}

extension CyclerType {
  public func receiveError(error: Error) {

  }

  public func add<T: ObservableConvertibleType>(action: T) {
    __queue.accept(action.asObservable().map { _ in })
  }
}

extension CyclerType where Self.Mutation == AnyMutation<Self.State> {

  public func commit(_ mutation: Mutation) {
    do {
      let mstorage = state.asMutableStateStorage()
      try mutation.mutate(mstorage)
    } catch {
      receiveError(error: error)
    }
  }

  public func commit(_ name: String, _ mutate: @escaping (MutableStorage<State>) throws -> Void) {
    commit(.init(name, mutate))
  }
}

private var _queue: Void?
private var _disposeBag: Void?

extension CyclerType {

  fileprivate var __disposeBag: DisposeBag {
    if let disposeBag = objc_getAssociatedObject(self, &_disposeBag) as? DisposeBag {
      return disposeBag
    } else {
      let disposeBag = DisposeBag()
      objc_setAssociatedObject(self, &_disposeBag, disposeBag, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return disposeBag
    }
  }

  var __queue: PublishRelay<Observable<Void>> {
    if let queue = objc_getAssociatedObject(self, &_queue) as? PublishRelay<Observable<Void>> {
      return queue
    } else {

      let queue = PublishRelay<Observable<Void>>()
      queue
        .observeOn(MainScheduler.instance)
        .map { [weak self] in
          $0
            .observeOn(MainScheduler.instance)
            .do(onError: { [weak self] error in
              self?.receiveError(error: error)
            })
            .materialize()
        }
        .merge()
        .observeOn(MainScheduler.instance)
        .subscribe()
        .disposed(by: __disposeBag)

      objc_setAssociatedObject(self, &_queue, queue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return queue
    }
  }
}

extension CyclerType where Activity == NoActivity {

  public var activity: Signal<Activity> {
    assertionFailure("\(self) does not have Activity")
    return .empty()
  }
}

extension CyclerCoreType where State == NoState {

  public var state: Storage<State> {
    assertionFailure("\(self) does not have State")
    return .init(.init(NoState()))
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

    let state = m_state.asStateStorage()

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
  }

  public func update(_ execute: @escaping (inout T) throws -> Void) rethrows {
    try execute(&writableValue)
  }

  public func update<E>(_ value: E?, _ keyPath: WritableKeyPath<T, E?>) {
    writableValue[keyPath: keyPath] = value
  }

  public func updateIfChanged<E>(_ value: E?, _ keyPath: WritableKeyPath<T, E?>, comparer: (E?, E?) -> Bool) {
    guard comparer(writableValue[keyPath: keyPath], value) == false else { return }
    writableValue[keyPath: keyPath] = value
  }

  public func updateIfChanged<E: Equatable>(_ value: E?, _ keyPath: WritableKeyPath<T, E?>, comparer: (E?, E?) -> Bool = { $0 == $1 }) {
    guard comparer(writableValue[keyPath: keyPath], value) == false else { return }
    writableValue[keyPath: keyPath] = value
  }

  public func updateIfChanged<E>(_ value: E, _ keyPath: WritableKeyPath<T, E>, comparer: (E, E) -> Bool) {
    guard comparer(writableValue[keyPath: keyPath], value) == false else { return }
    writableValue[keyPath: keyPath] = value
  }

  public func updateIfChanged<E : Equatable>(_ value: E, _ keyPath: WritableKeyPath<T, E>, comparer: (E, E) -> Bool = { $0 == $1 }) {
    guard comparer(writableValue[keyPath: keyPath], value) == false else { return }
    writableValue[keyPath: keyPath] = value
  }

  public func update<E>(_ value: E, _ keyPath: WritableKeyPath<T, E>) {
    writableValue[keyPath: keyPath] = value
  }

  public func binder<Source: ObservableType>(_ execute: @escaping (inout T, Source.E) -> Void) -> (Source) -> Disposable {
    return { source in
      source
        .do(onNext: { [weak self] e in
          guard let `self` = self else { return }
          execute(&self.writableValue, e)
        })
        .subscribe()
    }
  }

  public func asStateStorage() -> Storage<T> {
    return .init(self)
  }
}
