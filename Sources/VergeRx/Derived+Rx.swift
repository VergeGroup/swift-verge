import Foundation

#if !COCOAPODS
import Verge
#endif

import RxSwift
import RxCocoa

extension Reactive where Base : DerivedType {

  /// An observable that repeatedly emits the changes when state updated
  ///
  /// Guarantees to emit the first event on started subscribing.
  ///
  /// - Parameter startsFromInitial: Make the first changes object's hasChanges always return true.
  /// - Returns:
  @available(*, deprecated, renamed: "stateObservable()")
  public func valueObservable() -> Observable<Changes<Base.Value>> {
    self.stateObservable()
  }
}
