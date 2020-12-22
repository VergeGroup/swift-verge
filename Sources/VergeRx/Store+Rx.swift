
import Foundation

#if !COCOAPODS
import Verge
#endif

import RxSwift
import RxCocoa

fileprivate var storage_subject: Void?

extension Storage: ReactiveCompatible {}
extension Store: ReactiveCompatible {}

extension Reactive where Base : StoreType {
  
  private var storage: StateStorage<Changes<Base.State>> {
    unsafeBitCast(base.asStore().__backingStorage, to: StateStorage<Changes<Base.State>>.self)
  }
  
  private var activityEmitter: EventEmitter<Base.Activity> {
    unsafeBitCast(base.asStore().__activityEmitter, to: EventEmitter<Base.Activity>.self)
  }
  
  /// An observable that repeatedly emits the changes when state updated
  ///
  /// Guarantees to emit the first event on started subscribing.
  ///
  /// - Parameter startsFromInitial: Make the first changes object's hasChanges always return true.
  /// - Returns:
  public func stateObservable(startsFromInitial: Bool = true) -> Observable<Changes<Base.State>> {
    if startsFromInitial {
      return storage
        .asObservable()
        .skip(1)
        .startWith(storage.value.droppedPrevious())
    } else {
      return storage
        .asObservable()
    }
  }
  
  /// An observable that repeatedly emits the changes when state updated
  ///
  /// Guarantees to emit the first event on started subscribing.
  ///
  /// - Parameter startsFromInitial: Make the first changes object's hasChanges always return true.
  /// - Returns:
  @available(*, deprecated, renamed: "stateObservable")
  public func changesObservable(startsFromInitial: Bool = true) -> Observable<Changes<Base.State>> {
    if startsFromInitial {
      return storage
        .asObservable()
        .skip(1)
        .startWith(storage.value.droppedPrevious())
    } else {
      return storage
        .asObservable()
    }
  }

  public var activitySignal: Signal<Base.Activity> {
    activityEmitter.asSignal()
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
        pre = pre!.makeNextChanges(with: element, from: trace, modification: .indeterminate)
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
    changed(\.root)
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
    changedDriver(\.root)
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
  public func changed<S>(_ selector: @escaping (Changes<Element.Value>) -> S, _ compare: @escaping (S, S) -> Bool) -> Observable<S> {
    
    return flatMap { changes -> Observable<S> in
      let _r = changes.asChanges().ifChanged(selector, .init(compare)) { value in
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
  public func changed<S : Equatable>(_ selector: @escaping (Changes<Element.Value>) -> S) -> Observable<S> {
    return changed(selector, ==)
  }
    
  /// Returns an observable sequence that contains only changed elements according to the `comparer`.
  ///
  /// Using Changes under
  ///
  /// - Parameters:
  ///   - selector:
  ///   - compare:
  /// - Returns: Returns an observable sequence that contains only changed elements according to the `comparer`.
  public func changedDriver<S>(_ selector: @escaping (Changes<Element.Value>) -> S, _ compare: @escaping (S, S) -> Bool) -> Driver<S> {
    changed(selector, compare)
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
  public func changedDriver<S : Equatable>(_ selector: @escaping (Changes<Element.Value>) -> S) -> Driver<S> {
    return changedDriver(selector, ==)
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

extension Reactive where Base : StoreType {

  public func commitBinder<S>(
    scheduler: ImmediateSchedulerType = MainScheduler(),
    mutate: @escaping (inout InoutRef<Base.State>, S) -> Void
  ) -> Binder<S> {

    return Binder<S>(base, scheduler: scheduler) { t, e in
      t.asStore().commit { s in
        mutate(&s, e)
      }
    }
    
  }

  public func commitBinder<S>(
    scheduler: ImmediateSchedulerType = MainScheduler(),
    mutate: @escaping (inout InoutRef<Base.State>, S?) -> Void
  ) -> Binder<S?> {

    return Binder<S?>(base, scheduler: scheduler) { t, e in
      t.asStore().commit { s in
        mutate(&s, e)
      }
    }

  }

  public func commitBinder<S>(
    scheduler: ImmediateSchedulerType = MainScheduler(),
    target: WritableKeyPath<Base.State, S>
  ) -> Binder<S> {

    return Binder<S>(base, scheduler: scheduler) { t, e in
      t.asStore().commit { s in
        s[keyPath: target] = e
      }
    }

  }

  public func commitBinder<S>(
    scheduler: ImmediateSchedulerType = MainScheduler(),
    target: WritableKeyPath<Base.State, S?>
  ) -> Binder<S?> {

    return Binder<S?>(base, scheduler: scheduler) { t, e in
      t.asStore().commit { s in
        s[keyPath: target] = e
      }
    }

  }
}

