
import Foundation
import Combine

import JAYSON
import Moya
import VergeStore

public struct LoggedOutServiceState {
  
}

public final class LoggedOutService: BackendStore.ScopedDispatcher<LoggedOutServiceState> {
  
  let apiProvider = MoyaProvider<MultiTarget>()

  init(targetStore: WrappedStore) {
    super.init(targetStore: targetStore, scope: \.loggedOut)
  }
  
  public func fetchToken(code: Auth.AuthCode) -> Future<AuthResponse, MoyaError> {
    Future<AuthResponse, MoyaError> { (promise) in
      self.apiProvider.request(.init(APIRequests.token(code: code))) { (result) in
        switch result {
        case .success(let response):
          let auth = try! AuthResponse.init(from: try! JSON(data: response.data))
          promise(.success(auth))
        case .failure(let error):
          promise(.failure(error))
        }
      }
    }
  }
}

public final class LoggedOutStack {

  public let service: LoggedOutService
  
  init(store: BackendStore) {
    self.service = .init(targetStore: store)
  }
}
