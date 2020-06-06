
import Foundation
import VergeStore

public struct BackendState {

  @Fragment public var loggedOut: LoggedOutBackendState = .init()
  @Fragment public var loggedIn: LoggedInBackendState?

  public var session: RealmObjects.Session!
}
