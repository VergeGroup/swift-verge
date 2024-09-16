
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
  
  /// An observable that repeatedly emits the changes when state updated
  ///
  /// Guarantees to emit the first event on started subscribing.
  ///
  /// - Parameter startsFromInitial: Make the first changes object's hasChanges always return true.
  /// - Returns:
  public func stateInfallible(startsFromInitial: Bool = true) -> Infallible<Changes<Base.TargetStore.State>> {
    stateObservable()
      .asInfallible(onErrorRecover: { _ in fatalError() })
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

extension ObservableType where Element : Equatable {
    
  /// Make Changes sequense from current sequence
  /// - Returns:
  public func changes(
    initial: Changes<Element>? = nil,
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line
  ) -> Observable<Changes<Element>> {

    let trace = MutationTrace(
      name: name,
      file: file,
      function: function,
      line: line
    )
    
    return scan(into: initial, accumulator: { (pre, element) in
      if pre == nil {
        pre = Changes<Element>.init(old: nil, new: element)
      } else {
        pre = pre!.makeNextChanges(with: element, from: [trace], modification: .indeterminate, transaction: .init())
      }
    })
    .map { $0! }

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
  
  /// Returns an observable sequence that contains only changed elements according to the `comparer`.
  ///
  /// Using Changes under
  ///
  /// - Parameters:
  ///   - selector:
  ///   - compare:
  /// - Returns: Returns an observable sequence that contains only changed elements according to the `comparer`.
  public func changedDriver() -> Driver<Element.Value> {
    changedDriver({ $0 })
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
    
  /// Returns an observable sequence that contains only changed elements according to the `comparer`.
  ///
  /// Using Changes under
  ///
  /// - Parameters:
  ///   - selector:
  ///   - compare:
  /// - Returns: Returns an observable sequence that contains only changed elements according to the `comparer`.
  public func changedDriver<S>(_ selector: @escaping (Element.Value) -> S, _ comparer: some TypedComparator<S>) -> Driver<S> {
    changed(selector, comparer)
        .asDriver(onErrorRecover: { _ in .empty() })
  }
  
  /// Returns an observable sequence that contains only changed elements according to the `comparer`.
  ///
  /// Using Changes under
  ///
  /// - Parameters:
  ///   - selector:
  ///   - comparer:
  /// - Returns: Returns an observable sequence that contains only changed elements according to the `comparer`.
  public func changedDriver<S : Equatable>(_ selector: @escaping (Element.Value) -> S) -> Driver<S> {
    return changedDriver(selector, EqualityComparator())
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

  public func asSignal() -> Signal<Event> {
    self.publisher.asObservable().asSignal(onErrorRecover: { _ in fatalError("never happen") })
  }
  
}

extension Reactive where Base : StoreDriverType {

  public func commitBinder<S>(
    scheduler: ImmediateSchedulerType = MainScheduler(),
    mutate: @escaping (inout InoutRef<Base.TargetStore.State>, S) -> Void
  ) -> Binder<S> {

    return Binder<S>(base, scheduler: scheduler) { t, e in
      t.store.asStore().commit { s in
        mutate(&s, e)
      }
    }
    
  }

  public func commitBinder<S>(
    scheduler: ImmediateSchedulerType = MainScheduler(),
    mutate: @escaping (inout InoutRef<Base.TargetStore.State>, S?) -> Void
  ) -> Binder<S?> {

    return Binder<S?>(base, scheduler: scheduler) { t, e in
      t.store.asStore().commit { s in
        mutate(&s, e)
      }
    }

  }

  public func commitBinder<S>(
    scheduler: ImmediateSchedulerType = MainScheduler(),
    target: WritableKeyPath<Base.TargetStore.State, S>
  ) -> Binder<S> {

    return Binder<S>(base, scheduler: scheduler) { t, e in
      t.store.asStore().commit { s in
        s[keyPath: target] = e
      }
    }

  }

  public func commitBinder<S>(
    scheduler: ImmediateSchedulerType = MainScheduler(),
    target: WritableKeyPath<Base.TargetStore.State, S?>
  ) -> Binder<S?> {

    return Binder<S?>(base, scheduler: scheduler) { t, e in
      t.store.asStore().commit { s in
        s[keyPath: target] = e
      }
    }

  }
}

