
import Foundation

import RxSwift
import RxCocoa

private var storage_subject: Void?
private var storage_diposeBag: Void?

extension Storage {

  private var subject: BehaviorRelay<T> {

    if let associated = objc_getAssociatedObject(self, &storage_subject) as? BehaviorRelay<T> {

      return associated

    } else {

      let associated = BehaviorRelay<T>.init(value: value)
      objc_setAssociatedObject(self, &storage_subject, associated, .OBJC_ASSOCIATION_RETAIN)

      add(subscriber: { (value) in
        associated.accept(value)
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
  
  /// Returns an observable sequence that contains only changed elements according to the `comparer`.
  ///
  /// - Parameters:
  ///   - target: KeyPath to property
  ///   - comparer: 
  /// - Returns: Returns an observable sequence that contains only changed elements according to the `comparer`.
  public func changed<S>(_ target: KeyPath<T, S>, _ comparer: @escaping (S, S) throws -> Bool) -> Observable<S> {
    return
      asObservable()
        .map { $0[keyPath: target] }
        .distinctUntilChanged(comparer)
  }

  public func changed<S : Equatable>(_ target: KeyPath<T, S>) -> Observable<S> {
    return changed(target, ==)
  }
  
  public func changed<S>(_ selector: @escaping (T) -> S, _ comparer: @escaping (S, S) throws -> Bool) -> Observable<S> {
    return
      asObservable()
        .map(selector)
        .distinctUntilChanged(comparer)
  }
  
  public func changed<S : Equatable>(_ selector: @escaping (T) -> S) -> Observable<S> {
    return changed(selector, ==)
  }

  /// Returns an observable sequence as Driver that contains only changed elements according to the `comparer`.
  ///
  /// - Parameters:
  ///   - target: KeyPath to property
  ///   - comparer:
  /// - Returns: Returns an observable sequence as Driver that contains only changed elements according to the `comparer`.
  public func changedDriver<S>(_ target: KeyPath<T, S>, _ comparer: @escaping (S, S) throws -> Bool) -> Driver<S> {
    return
      asObservable()
        .map { $0[keyPath: target] }
        .distinctUntilChanged(comparer)
        .asDriver(onErrorRecover: { _ in .empty() })
  }
  
  public func changedDriver<S : Equatable>(_ target: KeyPath<T, S>) -> Driver<S> {
    return changedDriver(target, ==)
  }
  
  public func changedDriver<S>(_ selector: @escaping (T) -> S, _ comparer: @escaping (S, S) throws -> Bool) -> Driver<S> {
    return
      asObservable()
        .map(selector)
        .distinctUntilChanged(comparer)
        .asDriver(onErrorRecover: { _ in .empty() })
  }
  
  public func changedDriver<S : Equatable>(_ selector: @escaping (T) -> S) -> Driver<S> {
    return changedDriver(selector, ==)
  }
  
  /// Returns an observable sequence
  ///
  /// - Returns: Returns an observable sequence
  public func asObservable() -> Observable<T> {
    return subject.asObservable()
  }

  public func asObservable<S>(keyPath: KeyPath<T, S>) -> Observable<S> {
    return asObservable()
      .map { $0[keyPath: keyPath] }
  }

  /// Returns an observable sequence as Driver
  ///
  /// - Returns: Returns an observable sequence as Driver
  public func asDriver() -> Driver<T> {
    return subject.asDriver()
  }

  public func asDriver<S>(keyPath: KeyPath<T, S>) -> Driver<S> {
    return asDriver()
      .map { $0[keyPath: keyPath] }
  }

  /// Projects each property of Value into a new form.
  ///
  /// - Parameter keyPath:
  /// - Returns:
  public func map<U>(_ keyPath: KeyPath<T, U>) -> Storage<U> {
    return
      map {
        $0[keyPath: keyPath]
    }
  }

  /// Projects each property of Value into a new form.
  ///
  /// - Parameter keyPath:
  /// - Returns: 
  public func map<U>(_ closure: @escaping (T) -> U) -> Storage<U> {

    let m_state = MutableStorage.init(closure(value))

    let state = m_state.asStorage()

    let subscription = asObservable()
      .map(closure)
      .subscribe(onNext: { [weak m_state] o in
        m_state?.replace(o)
      })

    state.disposeBag.insert(subscription)
    disposeBag.insert(subscription)

    return state
  }
}
