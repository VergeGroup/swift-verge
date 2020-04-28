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

extension Derived {
  
  public convenience init(_ getter: RxGetter<Value>) {
    self.init(
      get: .init(map: { $0 }),
      set: { _ in },
      initialUpstreamState: getter.value,
      subscribeUpstreamState: { (callback) -> CancellableType in
        
        let disposable = getter.subscribe(onNext: { value in
          callback(value)
        })
                  
        return VergeAnyCancellable {
          disposable.dispose()
        }
    },
      retainsUpstream: getter
    )
  }
  
}

public protocol RxGetterType: GetterType {
  
  func asObservable() -> Observable<Output>
}

public class RxGetter<Output>: GetterBase<Output>, RxGetterType, ObservableType {
    
  public typealias Element = Output
  
  public static func constant<Output>(_ value: Output) -> RxGetter<Output> {
    .init(from: Observable.just(value))
  }
  
  let output: BehaviorSubject<Output>
  
  private let disposeBag: DisposeBag
  
  public override var value: Output {
    try! output.value()
  }
    
  fileprivate init<O: ObservableConvertibleType>(from observable: O, initialValue: O.Element) where O.Element == Output {
    
    VergeSignpostTransaction("RxGetter.init").end()
    
    let bag = DisposeBag()
    
    let shared = observable
      .asObservable()
      .do(onNext: { _ in
        VergeSignpostTransaction("RxGetter.receiveNewValue").end()
      })
      .share(replay: 1, scope: .whileConnected)
    
    let subject = BehaviorSubject<Output>(value: initialValue)
    
    self.disposeBag = bag
    self.output = subject
    
    shared.subscribe(onNext: {
      subject.onNext($0)
    })
      .disposed(by: disposeBag)
    
  }
  
  public convenience init(from derived: Derived<Output>) {
    self.init(from: derived.rx.valueObservable)
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
  public convenience init<O: ObservableConvertibleType>(from observable: O) where O.Element == Output {
    
    VergeSignpostTransaction("RxGetter.init").end()
    
    let bag = DisposeBag()
    
    let shared = observable
      .asObservable()
      .share(replay: 1, scope: .whileConnected)
               
    var initialValue: Output!
    
    let waiter = shared.subscribe()
    defer {
      waiter.dispose()
    }
    
    shared.take(1)
      .subscribe(onNext: { value in
        initialValue = value
      })
      .disposed(by: bag)
          
    precondition(initialValue != nil, "Don't use asynchronous operator in \(observable), and it must emit the value immediately.")
        
    self.init(from: shared, initialValue: initialValue)
    
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
extension Store: ReactiveCompatible {}

extension Reactive where Base : StoreType {
  
  public typealias Value = Base.State
  
  fileprivate func makeStream<Output>(
    from components: GetterComponents<Value, Output>
  ) -> (Observable<Changes<Output>>, Changes<Output>) {
    
    let initialValue = Changes<Output>.init(old: nil, new: components.transform(base.asStore().changes.current)) 
          
    let baseStream = base.asStore().rx.changesObservable(startsFromInitial: true)
      .skip(1)
      .do(onNext: { [closure = components.onPreFilterWillReceive] value in
        closure(value.current)
      })
      .filter({ value in
        let hasChanges = !components.preFilter(value)
        if !hasChanges {
          VergeSignpostTransaction("RxGetter.hitPreFilter").end()
        }
        return hasChanges
      })
      .do(onNext: { [closure = components.onTransformWillReceive] value in
        closure(value.current)
      })
      .map({ value in
        components.transform(value.current)
      })
      .changes(initial: initialValue) // makes new Changes Object
      .filter({ value in
        
        let hasChanges = !components.postFilter(value)
        if !hasChanges {
          VergeSignpostTransaction("RxGetter.hitPostFilter").end()
        }
        return hasChanges
      })
      .do(onNext: { [closure = components.onPostFilterWillEmit] value in
        closure(value.current)
      })
    
    return (baseStream, initialValue)
  }
  
  public func makeGetter<Output>(
    from components: GetterComponents<Value, Output>
  ) -> RxGetterSource<Value, Output> {
    
    let (stream, initialValue) = makeStream(from: components)
    let getter = RxGetterSource<Base.State, Output>.init(from: stream.map { $0.current }, initialValue: initialValue.current)
    return getter
  }
  
  public func makeChangesGetter<Output>(
    from components: GetterComponents<Value, Output>
  ) -> RxGetterSource<Value, Changes<Output>> {
        
    let (stream, initialValue) = makeStream(from: components)
    let getter = RxGetterSource<Base.State, Changes<Output>>.init(from: stream, initialValue: initialValue)
    
    return getter
  }
      
  public func getterBuilder() -> GetterBuilderMethodChain<GetterBuilderTrait.Rx, Base, Base.State> {
    .init(target: base)
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

extension GetterBuilderTransformMethodChain where Trait == GetterBuilderTrait.Rx, Context : StoreType & ReactiveCompatible, Context.State == Input {
  
  public func build() -> RxGetterSource<Input, Output> {
    target.rx.makeGetter(from: makeGetterComponents())
  }
  
  public func buildChanges() -> RxGetterSource<Input, Changes<Output>> {
    target.rx.makeChangesGetter(from: makeGetterComponents())
  }
  
}

extension GetterBuilderPostFilterMethodChain where Trait == GetterBuilderTrait.Rx, Context : StoreType & ReactiveCompatible, Context.State == Input {
  
  public func build() -> RxGetterSource<Input, Output> {
    target.rx.makeGetter(from: makeGetterComponents())
  }
  
  public func buildChanges() -> RxGetterSource<Input, Changes<Output>> {
    target.rx.makeChangesGetter(from: makeGetterComponents())
  }
  
}
