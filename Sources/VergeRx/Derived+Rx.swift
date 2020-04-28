import Foundation

#if !COCOAPODS
import VergeStore
import VergeCore
#endif

import RxSwift
import RxCocoa

extension Derived: ReactiveCompatible {
  
}

extension Reactive where Base : DerivedType {
  
  private var store: Store<Base.Value, Never> {
    unsafeBitCast(base.asDerived()._innerStore, to: Store<Base.Value, Never>.self)
  }
  
  /// An observable that repeatedly emits the current state when state updated
  ///
  /// Guarantees to emit the first event on started
  public var valueObservable: Observable<Base.Value> {
    store.rx.stateObservable
      .do(onDispose: {
        withExtendedLifetime(self) {}
      })
  }
  
  /// An observable that repeatedly emits the changes when state updated
  ///
  /// Guarantees to emit the first event on started subscribing.
  ///
  /// - Parameter startsFromInitial: Make the first changes object's hasChanges always return true.
  /// - Returns:
  public func changesObservable(startsFromInitial: Bool = true) -> Observable<Changes<Base.Value>> {
    store.rx.changesObservable()
      .do(onDispose: {
        withExtendedLifetime(self) {}
      })
  }
    
}
