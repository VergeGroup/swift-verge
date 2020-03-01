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
  
  public override var value: Output {
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
    
    VergeSignpostTransaction("RxGetter.init").end()
    
    let pipe = observable
      .asObservable()
      .do(onNext: { _ in
        VergeSignpostTransaction("RxGetter.receiveNewValue").end()
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
    VergeSignpostTransaction("RxGetter.deinit").end()
  }
  
  public func subscribe<Observer>(_ observer: Observer) -> Disposable where Observer : ObserverType, Element == Observer.Element {
    output
      .do(onDispose: {
        withExtendedLifetime(self) {}
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
        let result = !preComparer.equals(input: value)
        if !result {
          VergeSignpostTransaction("RxGetter.hitPreFilter").end()
        }
        return result
    }
    .map(builder.transform)
    
    let pipe: Observable<Output>
    
    if let comparer = postComparer {
      pipe = baseStream.filter { value in
        let result = !comparer.equals(input: value)
        if !result {
          VergeSignpostTransaction("RxGetter.hitPostFilter").end()
        }
        return result
      }
    } else {
      pipe = baseStream
    }
    
    let getter = RxGetterSource<Base.Value, Output>.init(from: pipe)
    
    return getter
  }
      
  /// Dummy for Xcode's code completion
  @available(*, deprecated, message: "Dummy method")
  public func makeGetter(_ make: (GetterBuilderMethodChain<Value>) -> Never) -> Never {
    fatalError()
  }
  
  /// Dummy for Xcode's code completion
  @available(*, deprecated, message: "You need to call `.map` more.")
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
  
}

extension ObservableConvertibleType {
    
  /// Casts to Getter object from stream.
  ///
  /// - Attention: Stream object must be that emits event synchronously on subscribed to create RxGetter. Otherwise, this function would cause a crash.
  public func unsafeGetterCast() -> RxGetter<Element> {
    .init(from: self)
  }
}
