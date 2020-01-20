//
//  RxGetter.swift
//  VergeGetterRx
//
//  Created by muukii on 2020/01/09.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import RxSwift

#if !COCOAPODS
import VergeStore
import VergeCore
#endif

public protocol RxGetterType: GetterType {
  
  func asObservable() -> Observable<Output>
}

public class RxGetter<Output>: GetterBase<Output>, RxGetterType, ObservableType {
    
  public typealias Element = Output
  
  public static func constant<Output>(_ value: Output) -> RxGetter<Output> {
    .init(from: Observable.just(value))
  }
  
  let output: BehaviorSubject<Output>
  
  private let disposeBag = DisposeBag()
  
  public final override var value: Output {
    try! output.value()
  }
      
  /// Initialize from observable
  ///
  /// - Attension: Please don't use operator that dispatches asynchronously.
  /// - Parameter observable:
  public convenience init<O: ObservableConvertibleType>(from observable: () -> O) where O.Element == Output {
    self.init(from: observable())
  }
  
  /// Initialize from observable
  ///
  /// - Attension: Please don't use operator that dispatches asynchronously.
  /// - Parameter observable:
  public init<O: ObservableConvertibleType>(from observable: O) where O.Element == Output {
    
    vergeSignpostEvent("RxGetter.init")
    
    let pipe = observable
      .asObservable()
      .do(onNext: { _ in
        vergeSignpostEvent("RxGetter.receiveNewValue")
      })
      .share(replay: 1, scope: .forever)
    
    var initialValue: Output!
    
    _ = pipe.take(1).subscribe(onNext: { value in
      initialValue = value
    })
    
    precondition(initialValue != nil, "Don't use asynchronous operator in \(observable), and it must emit the value immediately.")
    
    let subject = BehaviorSubject<Output>(value: initialValue)
    
    self.output = subject
    
    pipe.subscribe(onNext: {
      subject.onNext($0)
    })
    .disposed(by: disposeBag)
    
  }
  
  deinit {
    vergeSignpostEvent("RxGetter.deinit")
  }
  
  public func subscribe<Observer>(_ observer: Observer) -> Disposable where Observer : ObserverType, Element == Observer.Element {
    output
      .do(onDispose: {
        vergeSignpostEvent("RxGetter.DisposedSubscription")
      })
      .subscribe(observer)
  }
        
}

public final class RxGetterSource<Input, Output>: RxGetter<Output> {
             
  public func asGetter() -> RxGetter<Output> {
    self
  }
  
}

extension Storage: ReactiveCompatible {}
extension StoreBase: ReactiveCompatible {}

extension Reactive where Base : RxValueContainerType {
  
  public func makeGetter<Output>(
    filter: @escaping (Base.Value) -> Bool,
    map: @escaping (Base.Value) -> Output
  ) -> RxGetterSource<Base.Value, Output> {
    
    let pipe = base.asObservable()
      .filter(filter)
      .map(map)
    
    let getter = RxGetterSource<Base.Value, Output>.init(from: pipe)
    
    return getter
    
  }
  
  public func makeGetter<Output>(from: GetterBuilder<Base.Value, Output>) -> RxGetterSource<Base.Value, Output> {
    makeGetter(filter: from.filter, map: from.map)
  }
  
  public func makeGetter() -> RxGetterSource<Base.Value, Base.Value> {
    makeGetter(filter: { _ in true }, map: { $0 })
  }
  
}

extension ObservableConvertibleType {
    
  /// Casts to Getter object from stream.
  ///
  /// - Attention: Stream object must be that emits event synchronously on subscribed to create RxGetter. Otherwise, this function would cause a crash.
  public func unsafeGetterCast() -> RxGetter<Element> {
    .init(from: self)
  }
}
