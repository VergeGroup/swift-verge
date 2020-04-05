
import Foundation

import RxSwift
import RxCocoa

#if !COCOAPODS
import VergeCore
import VergeRx
#endif

private var storage_subject: Void?
private var storage_diposeBag: Void?

extension ReadonlyStorage {
  
  /// Returns an observable sequence that contains only changed elements according to the `comparer`.
  ///
  /// - Parameters:
  ///   - selector:
  ///   - comparer:
  /// - Returns: Returns an observable sequence that contains only changed elements according to the `comparer`.
  public func changed<S>(_ selector: @escaping (Value) -> S, _ comparer: @escaping (S, S) throws -> Bool) -> Observable<S> {
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
  public func changed<S : Equatable>(_ selector: @escaping (Value) -> S) -> Observable<S> {
    changed(selector, ==)
  }
  
  /// Returns an observable sequence that contains only changed elements according to the `comparer`.
  ///
  /// - Parameters:
  ///   - selector:
  ///   - comparer:
  /// - Returns: Returns an observable sequence that contains only changed elements according to the `comparer`.
  public func changedDriver<S>(_ selector: @escaping (Value) -> S, _ comparer: @escaping (S, S) throws -> Bool) -> Driver<S> {
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
  public func changedDriver<S : Equatable>(_ selector: @escaping (Value) -> S) -> Driver<S> {
    changedDriver(selector, ==)
  }
  
}
