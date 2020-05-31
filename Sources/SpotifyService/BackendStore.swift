
import Foundation
import VergeStore

public struct BackendState {

  public var loggedOut: LoggedOutServiceState = .init()
  public var loggedIn: LoggedInServiceState?
}

public enum BackendActivity {

}

public final class BackendStore: Store<BackendState, BackendActivity> {

}
