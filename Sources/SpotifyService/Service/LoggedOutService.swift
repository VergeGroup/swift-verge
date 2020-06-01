
import Foundation
import Combine

import JAYSON
import Moya
import VergeStore

public struct LoggedOutServiceState {

  var isLoginProcessing: Bool = false
}

public final class LoggedOutService: BackendStore.ScopedDispatcher<LoggedOutServiceState> {
  
  let apiProvider = MoyaProvider<MultiTarget>()

  init(targetStore: WrappedStore) {
    super.init(targetStore: targetStore, scope: \.loggedOut)
  }
  
  public func fetchToken(code: Auth.AuthCode) -> Future<AuthResponse, MoyaError> {

    apiProvider.requestPublisher(MultiTarget(APIRequests.token(code: code)))
      .map { response in
        try! AuthResponse.init(from: try! JSON(data: response.data))
    }
    .start()

  }
}

public final class LoggedOutStack {

  public let service: LoggedOutService
  
  init(store: BackendStore) {
    self.service = .init(targetStore: store)
  }
}
