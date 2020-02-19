
import Foundation

import RxSwift
import RxCocoa

#if !COCOAPODS
import VergeCore
import VergeRx
#endif

private var storage_subject: Void?
private var storage_diposeBag: Void?

extension Storage {
  
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
  ///   - selector: KeyPath to property
  ///   - comparer: 
  /// - Returns: Returns an observable sequence that contains only changed elements according to the `comparer`.
  public func changed<S>(_ selector: KeyPath<Value, S>, _ comparer: @escaping (S, S) throws -> Bool) -> Observable<S> {
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
  public func changed<S : Equatable>(_ selector: KeyPath<Value, S>) -> Observable<S> {
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
  
  /// Returns an observable sequence as Driver that contains only changed elements according to the `comparer`.
  ///
  /// - Parameters:
  ///   - selector: KeyPath to property
  ///   - comparer:
  /// - Returns: Returns an observable sequence as Driver that contains only changed elements according to the `comparer`.
  public func changedDriver<S>(_ selector: KeyPath<Value, S>, _ comparer: @escaping (S, S) throws -> Bool) -> Driver<S> {
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
  public func changedDriver<S : Equatable>(_ selector: KeyPath<Value, S>) -> Driver<S> {
    changedDriver(selector, ==)
  }
  
  /// Projects each property of Value into a new form.
  ///
  /// - Parameter keyPath:
  /// - Returns:
  public func map<U>(_ keyPath: KeyPath<Value, U>) -> ReadonlyStorage<U> {
    map {
      $0[keyPath: keyPath]
    }
  }
  
}
