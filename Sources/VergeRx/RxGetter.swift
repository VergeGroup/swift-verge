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

public class RxGetter<Output>: GetterBase<Output>, ObservableType {
  
  public typealias Element = Output
  
  let output: BehaviorSubject<Output>
  
  private let disposeBag = DisposeBag()
  
  public final override var value: Output {
    try! output.value()
  }
  
  public convenience init<O: ObservableConvertibleType>(from observable: () -> O) where O.Element == Output {
    self.init(from: observable())
  }
  
  public init<O: ObservableConvertibleType>(from observable: O) where O.Element == Output {
    
    let pipe = observable.asObservable().share(replay: 1, scope: .forever)
    
    var initialValue: Output!
    
    _ = pipe.debug().take(1).subscribe(onNext: { value in
      initialValue = value
    })
    
    precondition(initialValue != nil, "\(observable) can't use scheduler")
    
    self.output = BehaviorSubject<Output>(value: initialValue)
    
    pipe.subscribe(self.output).disposed(by: disposeBag)
    
  }
  
  public func subscribe<Observer>(_ observer: Observer) -> Disposable where Observer : ObserverType, Element == Observer.Element {
    output.subscribe(observer)   
  }
        
}

public final class RxGetterSource<Input, Output>: RxGetter<Output> {
          
  init(
    input: Observable<Output>
  ) {
        
    super.init(from: input)
            
  }
  
  public func asGetter() -> RxGetter<Output> {
    self
  }
  
}

extension Storage: ReactiveCompatible {}
extension StoreBase: ReactiveCompatible {}

extension Reactive where Base : RxValueContainerType {
  
  public func getter<Output>(
    filter: EqualityComputer<Base.Value>,
    map: @escaping (Base.Value) -> Output
  ) -> RxGetterSource<Base.Value, Output> {
    
    let pipe = base.asObservable()
      .distinctUntilChanged(filter)
      .map(map)
    
    let getter = RxGetterSource<Base.Value, Output>.init(input: pipe)
    
    return getter
    
  }
  
}

