import RxSwift
import Foundation
import Verge

fileprivate var storage_subject: Void?

extension ReadonlyStorage {

  private var subject: BehaviorSubject<Value> {

    objc_sync_enter(self)
    defer {
      objc_sync_exit(self)
    }

    if let associated = objc_getAssociatedObject(self, &storage_subject) as? BehaviorSubject<Value> {

      return associated

    } else {

      let associated = BehaviorSubject<Value>.init(value: value)
      objc_setAssociatedObject(self, &storage_subject, associated, .OBJC_ASSOCIATION_RETAIN)

      let lock = VergeConcurrency.RecursiveLock()

      sinkEvent { (event) in
        switch event {
        case .willUpdate:
          break
        case .didUpdate(let newValue):
          lock.lock(); defer { lock.unlock() }
          associated.onNext(newValue)
        case .willDeinit:
          lock.lock(); defer { lock.unlock() }
          associated.onCompleted()
        }
      }

      return associated
    }
  }

  /// Returns an observable sequence
  ///
  /// - Returns: Returns an observable sequence
  public func asObservable() -> Observable<Value> {
    subject.asObservable()
  }

  /// Returns an infallible sequence
  public func asInfallible() -> Infallible<Value> {
    subject.asInfallible(onErrorRecover: { _ in fatalError() })
  }

  public func asObservable<S>(keyPath: KeyPath<Value, S>) -> Observable<S> {
    asObservable()
      .map { $0[keyPath: keyPath] }
  }

  /// Returns an infallible sequence
  public func asInfallible<S>(keyPath: KeyPath<Value, S>) -> Infallible<S> {
    subject.asInfallible(onErrorRecover: { _ in fatalError() })
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
