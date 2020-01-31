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
  
  public typealias Value = Base.Value
  
  public func makeGetter<PreComapringKey, Output, PostComparingKey>(
    from builder: GetterBuilder<Value, PreComapringKey, Output, PostComparingKey>
  ) -> RxGetterSource<Value, Output> {
    
    let preComparer = builder.preFilter.build()
    let postComparer = builder.postFilter?.build()
    
    let baseStream = base.asObservable()
      .filter { value in
        !preComparer.equals(input: value)
    }
    .map(builder.transform)
    
    let pipe: Observable<Output>
    
    if let comparer = postComparer {
      pipe = baseStream.filter { value in
        !comparer.equals(input: value)
      }
    } else {
      pipe = baseStream
    }
    
    let getter = RxGetterSource<Base.Value, Output>.init(from: pipe)
    
    return getter
  }
      
  /// Dummy
  @available(*, deprecated, message: "Dummy method")
  public func makeGetter(_ make: (GetterBuilderMethodChain<Value>) -> Never) -> Never {
    fatalError()
  }
  
  /// Dummy
  @available(*, deprecated, message: "You need to call `map` more. This is Dummy method")
  public func makeGetter<PreComparingKey>(_ make: (GetterBuilderMethodChain<Value>) -> GetterBuilderPreFilterMethodChain<Value, PreComparingKey>) -> Never {
    fatalError()
  }
  
  /// Value -> [PreFilter -> Transform] -> Value
  public func makeGetter<PreComparingKey, Output>(_ make: (GetterBuilderMethodChain<Value>) -> GetterBuilderTransformMethodChain<Value, PreComparingKey, Output>) -> RxGetterSource<Value, Output> {
    return makeGetter(from: .from(make(.init())))
  }
  
  /// Value -> [PreFilter -> Transform -> PostFilter] -> Value
  public func makeGetter<PreComparingKey, Output, PostComparingKey>(_ make: (GetterBuilderMethodChain<Value>) -> GetterBuilderPostFilterMethodChain<Value, PreComparingKey, Output, PostComparingKey>) -> RxGetterSource<Value, Output> {
    return makeGetter(from: .from(make(.init())))
  }
  
  public func makeGetter<Output>(map: @escaping (Value) -> Output) -> RxGetterSource<Value, Output> where Output : Equatable {
    makeGetter {
      $0.preFilter(.noFilter)
        .map(map)
        .postFilter(comparer: .init(==))
    }
  }
  
  public func makeGetter<Output>(map keyPath: KeyPath<Value, Output>) -> RxGetterSource<Value, Output> where Output : Equatable {
    makeGetter(map: { $0[keyPath: keyPath] })
  }
  
  public func makeGetter<PreComparingKey>(preFilter:  EqualityComputerBuilder<Value, PreComparingKey>) -> RxGetterSource<Value, Value> {
    makeGetter {
      $0.preFilter(preFilter)
        .map { $0 }
    }
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
