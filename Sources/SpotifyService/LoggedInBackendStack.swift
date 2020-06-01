
import Foundation
import VergeStore

public final class LoggedInStack {

  public let service: LoggedInService

  public let derivedState: Derived<LoggedInBackendState>

  init(store: BackendStore) {

    self.service = .init(targetStore: store)

    self.derivedState = store.derived(
      MemoizeMap
        .map(\.loggedIn!)
        .dropsInput {
          $0.noChanges(\.$loggedIn.version)
      }
    )

  }
}
