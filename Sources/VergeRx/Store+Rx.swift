
import Foundation

#if !COCOAPODS
import VergeStore
import VergeCore
#endif

import RxSwift
import RxCocoa

fileprivate var storage_subject: Void?
fileprivate var storage_lock: Void?

extension Reactive where Base : StoreType {
  
  public var changesObservable: Observable<Changes<Base.State>> {
    base.asStore()._backingStorage.asObservable()
  }
  
  public var stateObservable: Observable<Base.State> {
    base.asStore()._backingStorage.asObservable().map { $0.current }
  }
  
  public var activitySignal: Signal<Base.Activity> {
    base.asStore()._eventEmitter.asSignal()
  }
  
}

extension StoreWrapperType {

  @_disfavoredOverload
  public var rx: Reactive<Self> {
    return .init(self)
  }

}

extension ObservableType {
    
  /// Make Changes sequense from current sequence
  /// - Returns:
  public func changes(initial: Changes<Element>? = nil) -> Observable<Changes<Element>> {
    
    scan(into: initial, accumulator: { (pre, element) in
      if pre == nil {
        pre = Changes<Element>.init(old: nil, new: element)
      } else {
        pre!.update(with: element)
      }
    })
      .map { $0! }

  }
  
}

extension ObservableType {
  /// Returns an observable sequence that contains only changed elements according to the `comparer`.
  ///
  /// - Parameters:
  ///   - selector:
  ///   - compare:
  /// - Returns: Returns an observable sequence that contains only changed elements according to the `comparer`.
  public func changed<S>(_ selector: @escaping (Element) -> S, _ compare: @escaping (S, S) throws -> Bool) -> Observable<S> {
    return
      asObservable()
        .map { selector($0) }
        .distinctUntilChanged(compare)
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
  ///   - selector:
  ///   - compare:
  /// - Returns: Returns an observable sequence that contains only changed elements according to the `comparer`.
  public func changedDriver<S>(_ selector: @escaping (Element) -> S, _ compare: @escaping (S, S) throws -> Bool) -> Driver<S> {
    return
      asObservable()
        .map { selector($0) }
        .distinctUntilChanged(compare)
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
  
}

extension EventEmitter {
  
  private var subject: PublishSubject<Event> {
    
    if let associated = objc_getAssociatedObject(self, &storage_subject) as? PublishSubject<Event> {
      
      return associated
      
    } else {
      
      let associated = PublishSubject<Event>()
      objc_setAssociatedObject(self, &storage_subject, associated, .OBJC_ASSOCIATION_RETAIN)
      
      let lock = NSRecursiveLock()
      
      add { (event) in
        lock.lock(); defer { lock.unlock() }
        associated.on(.next(event))
      }
      
      return associated
    }
  }
  
  public func asSignal() -> Signal<Event> {
    return subject.asSignal(onErrorSignalWith: .empty())
  }
  
}

extension ReadonlyStorage {
  
  private var subject: BehaviorSubject<Value> {
    
    lock(); defer { unlock() }

    if let associated = objc_getAssociatedObject(self, &storage_subject) as? BehaviorSubject<Value> {

      return associated

    } else {

      let associated = BehaviorSubject<Value>.init(value: value)
      objc_setAssociatedObject(self, &storage_subject, associated, .OBJC_ASSOCIATION_RETAIN)
      
      let lock = NSRecursiveLock()
      
      addDeinit {
        lock.lock(); defer { lock.unlock() }
        associated.onCompleted()
      }

      addDidUpdate(subscriber: { (value) in
        lock.lock(); defer { lock.unlock() }
        associated.onNext(value)
      })

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

