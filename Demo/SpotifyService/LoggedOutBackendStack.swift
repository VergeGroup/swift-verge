
import Foundation
import VergeStore

public final class LoggedOutStack {

  public let service: LoggedOutService

  public let derivedState: Derived<LoggedOutBackendState>

  init(store: BackendStore) {
    self.service = .init(targetStore: store)

    self.derivedState = store.derived(
      MemoizeMap
        .map(\.loggedOut)
        .dropsInput {
          $0.noChanges(\.$loggedOut)
      }
    )
  }
}
