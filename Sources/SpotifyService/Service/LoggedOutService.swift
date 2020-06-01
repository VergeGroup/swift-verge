
import Foundation
import Combine

import JAYSON
import Moya
import VergeStore

public final class LoggedOutService: BackendStore.ScopedDispatcher<LoggedOutBackendState> {
  
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
