
import Foundation

#if !COCOAPODS
@_spi(Package) import Verge
@_spi(EventEmitter) import Verge
#endif

import RxSwift
import RxCocoa


extension Store: ReactiveCompatible {}

extension Reactive where Base : StoreDriverType {
    
  /// An observable that repeatedly emits the changes when state updated
  ///
  /// Guarantees to emit the first event on started subscribing.
  ///
  /// - Parameter startsFromInitial: Make the first changes object's hasChanges always return true.
  /// - Returns:
  public func stateObservable() -> Observable<Changes<Base.TargetStore.State>> {
    base.store.asStore()._statePublisher().asObservable()
  }

  public func activitySignal() -> Signal<Base.TargetStore.Activity> {
    base.store.asStore()._activityPublisher().asObservable().asSignal(onErrorRecover: { _ in Signal.empty() })
  }
  
}

extension StoreDriverType {

  @_disfavoredOverload
  public var rx: Reactive<Self> {
    return .init(self)
  }

}

extension ObservableType where Element : ChangesType, Element.Value : Equatable {
  
  /// Returns an observable sequence that contains only changed elements according to the `comparer`.
  ///
  /// Using Changes under
  ///
  /// - Parameters:
  ///   - selector:
  ///   - compare:
  /// - Returns: Returns an observable sequence that contains only changed elements according to the `comparer`.
  public func changed() -> Observable<Element.Value> {
    changed({ $0 })
  }

}

extension ObservableType where Element : ChangesType {
      
  /// Returns an observable sequence that contains only changed elements according to the `comparer`.
  ///
  /// Using Changes under
  ///
  /// - Parameters:
  ///   - selector:
  ///   - compare:
  /// - Returns: Returns an observable sequence that contains only changed elements according to the `comparer`.
  public func changed<S>(_ selector: @escaping (Element.Value) -> S, _ comparer: some TypedComparator<S>) -> Observable<S> {

    return flatMap { changes -> Observable<S> in
      let _r = changes.asChanges().ifChanged(selector, comparer) { value in
        return value
      }
      return _r.map { .just($0) } ?? .empty()
    }
  }
  
  /// Returns an observable sequence that contains only changed elements according to the `comparer`.
  ///
  /// Using Changes under
  ///
  /// - Parameters:
  ///   - selector:
  ///   - comparer:
  /// - Returns: Returns an observable sequence that contains only changed elements according to the `comparer`.
  public func changed<S : Equatable>(_ selector: @escaping (Element.Value) -> S) -> Observable<S> {
    return changed(selector, EqualityComparator())
  }

}
