
import Foundation
import VergeStore
import Combine
import CombineExt

public final class LoggedInStack {

  public let service: LoggedInService

  public let derivedState: Derived<LoggedInBackendState>

  private let store: BackendStore

  init(
    externalDataSource: ExternalDataSource,
    store: BackendStore
  ) {

    self.service = .init(
      externalDataSource: externalDataSource,
      targetStore: store
    )

    self.store = store

    self.derivedState = store.derived(
      MemoizeMap
        .map(\.loggedIn!)
        .dropsInput {
          $0.noChanges(\.$loggedIn.version)
      }
    )

  }

  public func logout() -> Future<Void, Error> {
    Future { promise in
      // do something async operations
      BackendStackManager.shared.deactivate(stack: self)
      promise(.success(()))
    }
  }

}
