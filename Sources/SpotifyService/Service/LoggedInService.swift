import Foundation

import Moya
import VergeStore

public struct LoggedInServiceState {
  let auth: AuthResponse
  
  init(auth: AuthResponse) {
    self.auth = auth
  }
}

public final class LoggedInService: BackendStore.ScopedDispatcher<LoggedInServiceState> {

  private let apiProvider: MoyaProvider<Templates.JSONResponse.Auth.Request>
  
  init(targetStore: WrappedStore) {
    // TODO: Refresh-token
    let token = targetStore.state.loggedIn!.auth.accessToken
    let authPlugin = AccessTokenPlugin { _ in token }
    self.apiProvider = .init(plugins: [authPlugin])
    super.init(targetStore: targetStore, scope: \.loggedIn!)
  }
  
  public func fetchMe() {          
    apiProvider.request(APIRequests.me()) { (result) in
      print(result)
    }
  }
  
}


public final class LoggedInStack {

  public let service: LoggedInService
  
  init(store: BackendStore) {

    self.service = .init(targetStore: store)
    
  }
}
