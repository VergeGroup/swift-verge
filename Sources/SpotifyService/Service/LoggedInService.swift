import Foundation

import JAYSON
import Moya
import VergeStore
import Combine
import CombineExt
import VergeORM

public final class LoggedInService: BackendStore.ScopedDispatcher<LoggedInBackendState> {

  private let apiProvider: MoyaProvider<Templates.JSONResponse.Auth.Request>
  
  init(targetStore: WrappedStore) {
    // TODO: Refresh-token
    let token = targetStore.state.loggedIn!.auth.accessToken
    let authPlugin = AccessTokenPlugin { _ in token }
    self.apiProvider = .init(plugins: [authPlugin])
    super.init(targetStore: targetStore, scope: \.loggedIn!)
  }
  
  public func fetchMe() -> Future<Void, MoyaError> {

    apiProvider.requestPublisher(APIRequests.me())
      .handleEvents(receiveOutput: { response in
        do {
          let json = try JSON(data: response.data)
          try self.commit {
            try $0.db.performBatchUpdates { context in
              let me = try Entities.Me(from: json)
              context.me.insert(me)

              assert(context.me.all().count == 1)
            }
          }
        } catch {
          Log.error(error)
        }
      })
      .map { _ in }
      .start()
  }

  @discardableResult
  public func fetchTop() -> Future<Void, MoyaError> {
    apiProvider.requestPublisher(APIRequests.getMeTopArtist(limit: 20, offset: 0))
      .handleEvents(receiveOutput: { response in
        do {
          let json = try JSON(data: response.data)
          let items = try json.next("items").getArray().map { json in
            try Entities.Artist(from: json)
          }
          self.commit {
            $0.db.performBatchUpdates {
              $0.artists.insert(items)
              return
            }
          }
        } catch {
          Log.error(error)
        }
      })
      .map { _ in }
      .start()
  }
  
}


