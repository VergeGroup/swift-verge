
import Foundation

#if !COCOAPODS
import VergeStore
import VergeCore
#endif

import RxSwift
import RxCocoa

fileprivate var storage_subject: Void?
fileprivate var storage_diposeBag: Void?

extension Reactive where Base : StoreType {
  
  public var stateObservable: Observable<Base.State> {
    base.asStoreBase()._backingStorage.asObservable()
  }
  
  public var activitySignal: Signal<Base.Activity> {
    base.asStoreBase()._eventEmitter.asSignal()
  }
  
}

extension ObservableType where Element : StateType {
  /// Returns an observable sequence that contains only changed elements according to the `comparer`.
  ///
  /// - Parameters:
  ///   - selector:
  ///   - comparer:
  /// - Returns: Returns an observable sequence that contains only changed elements according to the `comparer`.
  public func changed<S>(_ selector: @escaping (Element) -> S, _ comparer: @escaping (S, S) throws -> Bool) -> Observable<S> {
    return
      asObservable()
        .map { selector($0) }
        .distinctUntilChanged(comparer)
  }
  
  /// Returns an observable sequence that contains only changed elements according to the `comparer`.
  ///
  /// - Parameters:
  ///   - selector:
  ///   - comparer:
  /// - Returns: Returns an observable sequence that contains only changed elements according to the `comparer`.
  public func changed<S : Equatable>(_ selector: @escaping (Element) -> S) -> Observable<S> {
    return changed(selector, ==)
  }
  
  /// Returns an observable sequence that contains only changed elements according to the `comparer`.
  ///
  /// - Parameters:
  ///   - selector: KeyPath to property
  ///   - comparer:
  /// - Returns: Returns an observable sequence that contains only changed elements according to the `comparer`.
  public func changed<S>(_ selector: KeyPath<Element, S>, _ comparer: @escaping (S, S) throws -> Bool) -> Observable<S> {
    return
      asObservable()
        .map { $0[keyPath: selector] }
        .distinctUntilChanged(comparer)
  }
      
  /// Returns an observable sequence that contains only changed elements according to the `comparer`.
  ///
  /// - Parameters:
  ///   - selector: KeyPath to property
  ///   - comparer:
  /// - Returns: Returns an observable sequence that contains only changed elements according to the `comparer`.
  public func changed<S : Equatable>(_ selector: KeyPath<Element, S>) -> Observable<S> {
    return changed(selector, ==)
  }
    
  /// Returns an observable sequence that contains only changed elements according to the `comparer`.
  ///
  /// - Parameters:
  ///   - selector:
  ///   - comparer:
  /// - Returns: Returns an observable sequence that contains only changed elements according to the `comparer`.
  public func changedDriver<S>(_ selector: @escaping (Element) -> S, _ comparer: @escaping (S, S) throws -> Bool) -> Driver<S> {
    return
      asObservable()
        .map { selector($0) }
        .distinctUntilChanged(comparer)
        .asDriver(onErrorRecover: { _ in .empty() })
  }
  
  /// Returns an observable sequence that contains only changed elements according to the `comparer`.
  ///
  /// - Parameters:
  ///   - selector:
  ///   - comparer:
  /// - Returns: Returns an observable sequence that contains only changed elements according to the `comparer`.
  public func changedDriver<S : Equatable>(_ selector: @escaping (Element) -> S) -> Driver<S> {
    return changedDriver(selector, ==)
  }
  
  /// Returns an observable sequence as Driver that contains only changed elements according to the `comparer`.
  ///
  /// - Parameters:
  ///   - selector: KeyPath to property
  ///   - comparer:
  /// - Returns: Returns an observable sequence as Driver that contains only changed elements according to the `comparer`.
  public func changedDriver<S>(_ selector: KeyPath<Element, S>, _ comparer: @escaping (S, S) throws -> Bool) -> Driver<S> {
    return
      asObservable()
        .map { $0[keyPath: selector] }
        .distinctUntilChanged(comparer)
        .asDriver(onErrorRecover: { _ in .empty() })
  }
  
  /// Returns an observable sequence as Driver that contains only changed elements according to the `comparer`.
  ///
  /// - Parameters:
  ///   - selector: KeyPath to property
  ///   - comparer:
  /// - Returns: Returns an observable sequence as Driver that contains only changed elements according to the `comparer`.
  public func changedDriver<S : Equatable>(_ selector: KeyPath<Element, S>) -> Driver<S> {
    return changedDriver(selector, ==)
  }
  
}

extension EventEmitter {
  
  private var subject: PublishRelay<Event> {
    
    if let associated = objc_getAssociatedObject(self, &storage_subject) as? PublishRelay<Event> {
      
      return associated
      
    } else {
      
      let associated = PublishRelay<Event>()
      objc_setAssociatedObject(self, &storage_subject, associated, .OBJC_ASSOCIATION_RETAIN)
      
      add { (event) in
        associated.accept(event)
      }
      
      return associated
    }
  }
  
  public func asSignal() -> Signal<Event> {
    return subject.asSignal()
  }
  
}

extension ReadonlyStorage {

  private var subject: BehaviorSubject<Value> {

    if let associated = objc_getAssociatedObject(self, &storage_subject) as? BehaviorSubject<Value> {

      return associated

    } else {

      let associated = BehaviorSubject<Value>.init(value: value)
      objc_setAssociatedObject(self, &storage_subject, associated, .OBJC_ASSOCIATION_RETAIN)
      
      addDeinit {
        associated.dispose()
      }

      addDidUpdate(subscriber: { (value) in
        associated.onNext(value)
      })

      return associated
    }
  }

  private var disposeBag: DisposeBag {

    if let associated = objc_getAssociatedObject(self, &storage_diposeBag) as? DisposeBag {

      return associated

    } else {

      let associated = DisposeBag()
      objc_setAssociatedObject(self, &storage_diposeBag, associated, .OBJC_ASSOCIATION_RETAIN)

      return associated
    }
  }
  
  /// Returns an observable sequence
  ///
  /// - Returns: Returns an observable sequence
  public func asObservable() -> Observable<Value> {
    subject.asObservable()
  }
  
  public func asObservable<S>(keyPath: KeyPath<Value, S>) -> Observable<S> {
    asObservable()
      .map { $0[keyPath: keyPath] }
  }
  
  public func asDriver() -> Driver<Value> {
    subject.asDriver(onErrorDriveWith: .empty())
  }
  
  public func asDriver<S>(keyPath: KeyPath<Value, S>) -> Driver<S> {
    return asDriver()
      .map { $0[keyPath: keyPath] }
  }

}

public protocol RxValueContainerType: ValueContainerType {
  
  func asObservable() -> Observable<Value>
  
}

extension Storage: RxValueContainerType {}

extension StoreBase: RxValueContainerType where State : StateType {
  public func asObservable() -> Observable<State> {
    rx.stateObservable
  }
}
