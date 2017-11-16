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

public protocol CyclerType : class {

  associatedtype State
  associatedtype Activity
  associatedtype Action

  var activity: Signal<Activity> { get }
  var state: StateStorage<State> { get }
  func reduce(state: MutableStateStorage<State>, action: Action) -> Observable<Void>
  func receiveError(error: Error)
}

extension CyclerType {
  public func receiveError(error: Error) {

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

extension CyclerType where Action == NoAction {

  public func reduce(state: MutableStateStorage<State>, action: Action) -> Observable<Void> {
    return .empty()
  }
}

extension CyclerType where Activity == NoActivity {

  public var activity: Signal<Activity> {
    assertionFailure("\(self) does not have Activity")
    return .empty()
  }
}

extension CyclerType where State == NoState {

  public var state: StateStorage<State> {
    assertionFailure("\(self) does not have State")
    return .init(.init(NoState()))
  }
}

extension CyclerType {

  public var action: Binder<Action> {
    return Binder<Action>.init(self) { (t, a) in
      t.run(a)
    }
  }

  public func run(_ action: Action) {

    __queue.accept(reduce(state: state.asMutableStateStorage(), action: action))
  }
}

public final class StateStorage<T> {

  public var value: T {
    return source.value
  }

  private let source: MutableStateStorage<T>
  private let disposeBag: DisposeBag = .init()

  public init(_ variable: MutableStateStorage<T>) {
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

  public func map<U>(_ closure: @escaping (T) -> U) -> StateStorage<U> {

    let m_state = MutableStateStorage.init(closure(value))

    let state = m_state.asStateStorage()

    asObservable()
      .map(closure)
      .subscribe(onNext: { [weak m_state] o in
        m_state?.source.accept(o)
      })
      .disposed(by: state.disposeBag)

    return state
  }

  fileprivate func asMutableStateStorage() -> MutableStateStorage<T> {
    return source
  }
}

public final class MutableStateStorage<T> {

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

  @available(*, deprecated: 0.1.0, renamed: "update(value:forKeyPath:)")
  public func update<E>(_ keyPath: WritableKeyPath<T, E?>, _ value: E?) {
    writableValue[keyPath: keyPath] = value
  }

  @available(*, deprecated: 0.1.0, renamed: "update(value:forKeyPath:)")
  public func update<E>(_ keyPath: WritableKeyPath<T, E>, _ value: E) {
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

  public func asStateStorage() -> StateStorage<T> {
    return .init(self)
  }
}

extension Observable {

  public func apply<S>(on state: MutableStateStorage<S>, keyPath: WritableKeyPath<S, E?>) -> Observable<E> {

    return self.do(onNext: { e in
      state.update(e, keyPath)
    })
  }

  public func apply<S>(on state: MutableStateStorage<S>, keyPath: WritableKeyPath<S, E>) -> Observable<E> {

    return self.do(onNext: { e in
      state.update(e, keyPath)
    })
  }

  public func applyIfChanged<S>(on state: MutableStateStorage<S>, keyPath: WritableKeyPath<S, E?>, comparer: @escaping  (E?, E?) -> Bool) -> Observable<E> {

    return self.do(onNext: { e in
      state.updateIfChanged(e, keyPath, comparer: comparer)
    })
  }

  public func applyIfChanged<S>(on state: MutableStateStorage<S>, keyPath: WritableKeyPath<S, E>, comparer: @escaping  (E, E) -> Bool) -> Observable<E> {

    return self.do(onNext: { e in
      state.updateIfChanged(e, keyPath, comparer: comparer)
    })
  }

  public func batch<S>(on state: MutableStateStorage<S>, apply: @escaping (inout S, E) -> Void) -> Observable<E> {

    return self.do(onNext: { e in
      state.update { s in
        apply(&s, e)
      }
    })
  }
}

extension Observable where E : Equatable {

  public func applyIfChanged<S>(on state: MutableStateStorage<S>, keyPath: WritableKeyPath<S, E>, comparer: @escaping  (E, E) -> Bool = { $0 == $1 }) -> Observable<E> {

    return self.do(onNext: { e in
      state.updateIfChanged(e, keyPath, comparer: comparer)
    })
  }

  public func applyIfChanged<S>(on state: MutableStateStorage<S>, keyPath: WritableKeyPath<S, E?>, comparer: @escaping  (E?, E?) -> Bool = { $0 == $1 }) -> Observable<E> {

    return self.do(onNext: { e in
      state.updateIfChanged(e, keyPath, comparer: comparer)
    })
  }
}

extension PrimitiveSequence where Trait == SingleTrait {

  public func apply<S>(on state: MutableStateStorage<S>, keyPath: WritableKeyPath<S, E?>) -> PrimitiveSequence<Trait, E> {

    return self.do(onNext: { e in
      state.update(e, keyPath)
    })
  }

  public func apply<S>(on state: MutableStateStorage<S>, keyPath: WritableKeyPath<S, E>) -> PrimitiveSequence<Trait, E> {

    return self.do(onNext: { e in
      state.update(e, keyPath)
    })
  }

  public func applyIfChanged<S>(on state: MutableStateStorage<S>, keyPath: WritableKeyPath<S, E?>, comparer: @escaping  (E?, E?) -> Bool) -> PrimitiveSequence<Trait, E> {

    return self.do(onNext: { e in
      state.updateIfChanged(e, keyPath, comparer: comparer)
    })
  }

  public func applyIfChanged<S>(on state: MutableStateStorage<S>, keyPath: WritableKeyPath<S, E>, comparer: @escaping  (E, E) -> Bool) -> PrimitiveSequence<Trait, E> {

    return self.do(onNext: { e in
      state.updateIfChanged(e, keyPath, comparer: comparer)
    })
  }

  public func batch<S>(on state: MutableStateStorage<S>, apply: @escaping (inout S, E) -> Void) -> PrimitiveSequence<Trait, E> {

    return self.do(onNext: { e in
      state.update { s in
        apply(&s, e)
      }
    })
  }
}

extension PrimitiveSequence where Trait == SingleTrait, Element : Equatable {

  public func applyIfChanged<S>(on state: MutableStateStorage<S>, keyPath: WritableKeyPath<S, E?>, comparer: @escaping  (E?, E?) -> Bool = { $0 == $1 }) -> PrimitiveSequence<Trait, E> {

    return self.do(onNext: { e in
      state.updateIfChanged(e, keyPath, comparer: comparer)
    })
  }

  public func applyIfChanged<S>(on state: MutableStateStorage<S>, keyPath: WritableKeyPath<S, E>, comparer: @escaping  (E, E) -> Bool = { $0 == $1 }) -> PrimitiveSequence<Trait, E> {

    return self.do(onNext: { e in
      state.updateIfChanged(e, keyPath, comparer: comparer)
    })
  }
}

extension PrimitiveSequence where Trait == MaybeTrait {

  public func apply<S>(on state: MutableStateStorage<S>, keyPath: WritableKeyPath<S, E?>) -> PrimitiveSequence<Trait, E> {

    return self.do(onNext: { e in
      state.update(e, keyPath)
    })
  }

  public func apply<S>(on state: MutableStateStorage<S>, keyPath: WritableKeyPath<S, E>) -> PrimitiveSequence<Trait, E> {

    return self.do(onNext: { e in
      state.update(e, keyPath)
    })
  }

  public func applyIfChanged<S>(on state: MutableStateStorage<S>, keyPath: WritableKeyPath<S, E?>, comparer: @escaping  (E?, E?) -> Bool) -> PrimitiveSequence<Trait, E> {

    return self.do(onNext: { e in
      state.updateIfChanged(e, keyPath, comparer: comparer)
    })
  }

  public func applyIfChanged<S>(on state: MutableStateStorage<S>, keyPath: WritableKeyPath<S, E>, comparer: @escaping  (E, E) -> Bool) -> PrimitiveSequence<Trait, E> {

    return self.do(onNext: { e in
      state.updateIfChanged(e, keyPath, comparer: comparer)
    })
  }

  public func batch<S>(on state: MutableStateStorage<S>, apply: @escaping (inout S, E) -> Void) -> PrimitiveSequence<Trait, E> {

    return self.do(onNext: { e in
      state.update { s in
        apply(&s, e)
      }
    })
  }
}

extension PrimitiveSequence where Trait == MaybeTrait, Element : Equatable {

  public func applyIfChanged<S>(on state: MutableStateStorage<S>, keyPath: WritableKeyPath<S, E?>, comparer: @escaping  (E?, E?) -> Bool = { $0 == $1 }) -> PrimitiveSequence<Trait, E> {

    return self.do(onNext: { e in
      state.updateIfChanged(e, keyPath, comparer: comparer)
    })
  }

  public func applyIfChanged<S>(on state: MutableStateStorage<S>, keyPath: WritableKeyPath<S, E>, comparer: @escaping  (E, E) -> Bool = { $0 == $1 }) -> PrimitiveSequence<Trait, E> {

    return self.do(onNext: { e in
      state.updateIfChanged(e, keyPath, comparer: comparer)
    })
  }
}
