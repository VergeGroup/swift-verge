//
// CycleViewModel
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
  func mutate(_ action: Action) -> Observable<Void>
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
        .map { $0.materialize() }
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

  public func mutate(_ action: Action) -> Observable<Void> {
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

    __queue.accept(mutate(action))
  }
}

public final class StateStorage<T> {

  public var value: T {
    return source.value
  }

  private let source: MutableStateStorage<T>

  public init(_ variable: MutableStateStorage<T>) {
    self.source = variable
  }

  public func asObservable() -> Observable<T> {
    return source.asObservable()
  }

  public func asDriver() -> Driver<T> {
    return source.asDriver()
  }
}

public final class MutableStateStorage<T> {

  public var value: T {
    get {
      return source.value
    }
    set {
      source.accept(newValue)
    }
  }

  private let source: BehaviorRelay<T>

  public init(_ value: T) {
    self.source = .init(value: value)
  }

  public func mutate(_ execute: @escaping (inout T) -> Void) {
    execute(&value)
  }

  public func binder<Source: ObservableType>(_ execute: @escaping (inout T, Source.E) -> Void) -> (Source) -> Disposable {
    return { source in
      source
        .do(onNext: { [weak self] e in
          guard let `self` = self else { return }
          execute(&self.value, e)
        })
        .subscribe()
    }
  }

  public func asObservable() -> Observable<T> {
    return source.asObservable()
  }

  public func asDriver() -> Driver<T> {
    return source.asDriver()
  }
}
