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

import Foundation

import RxSwift
import RxCocoa

public enum NoState {}
public enum NoActivity {}
public enum NoMutation {}
public enum NoAction {}

public protocol CycleViewModel : class {

  associatedtype State
  associatedtype Activity
  associatedtype Action
  associatedtype Mutation

  var activity: Signal<Activity> { get }
  var state: StateStorage<State> { get }
  func mutate(_ action: Action) -> Mutation
  func reduce(_ mutation: Mutation)
}

extension CycleViewModel where Action == Mutation {
  public func mutate(_ action: Action) -> Mutation {
    return action
  }
}

extension CycleViewModel where Activity == NoActivity {
  public var activity: Signal<Activity> {
    preconditionFailure("\(self) does not have Activity")
  }
}

extension CycleViewModel where State == NoState {
  public var state: StateStorage<State> {
    preconditionFailure("\(self) does not have State")
  }
}

extension CycleViewModel where Action == NoAction, Mutation == NoMutation {

  public func mutate(_ action: Action) -> Mutation {
    preconditionFailure("\(self) does not have Action")
  }

  public func reduce(_ mutation: Mutation) {
    preconditionFailure("\(self) does not have Mutation")
  }
}

extension CycleViewModel {

  public var action: Binder<Action> {
    return Binder<Action>.init(self) { (t, a) in
      t.reduce(self.mutate(a))
    }
  }

  public func run(_ action: Action) {
    self.reduce(self.mutate(action))
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

  public func mutate<Source: ObservableType>(_ execute: @escaping (inout T, Source.E) -> Void) -> (Source) -> Disposable {
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
