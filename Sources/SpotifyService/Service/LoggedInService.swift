import Foundation

import JAYSON
import Moya
import VergeStore
import Combine
import CombineExt
import VergeORM

public final class LoggedInService: BackendStore.ScopedDispatcher<LoggedInBackendState> {

  private let apiProvider: RefreshTokenProvider<Templates.JSONResponse.Auth.Request>

  init(
    externalDataSource: ExternalDataSource,
    targetStore: WrappedStore
  ) {

    let auth = try! targetStore.state.session!.composeAuthResponse()

    let _refreshTokenAPIProvider: MoyaProvider<AuthRequest> = .init()

    self.apiProvider = .init(tokenController: .init(initial: auth, refresh: { auth in
      _refreshTokenAPIProvider
        .requestPublisher(APIRequests.refreshToken(refreshToken: auth.refreshToken))
        .tryMap {
          let json = try JSON(data: $0.data)
          var newAuth = auth
          try newAuth.update(refreshTokenResponse: json)
          let realmWrapper = externalDataSource.makeUserDataRealm()
          realmWrapper.asyncWrite { transaction in
            let session = try transaction.object(ofType: RealmObjects.Session.self)
            session.update(with: newAuth)
          }
          return newAuth
      }
      .eraseToAnyPublisher()
    }))
    
    super.init(targetStore: targetStore, scope: \.loggedIn!)
  }
  
  public func fetchMe() -> Future<Void, Error> {

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
  public func fetchTop() -> Future<Void, Error> {
    apiProvider.requestPublisher(APIRequests.getMeTopArtist(limit: 20, offset: 0))
      .handleEvents(receiveOutput: { response in
        do {
          let json = try JSON(data: response.data)
          try self.commit {
            try $0.db.performBatchUpdates { context in
              let items = try json.next("items").getArray().map { json in
                try Entities.Artist(from: json, context: context)
              }
              context.artist.insert(items)
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

  @discardableResult
  public func fetchMePlaylist() -> Future<Void, Error> {

    apiProvider.requestPublisher(APIRequests.getMePlaylist(limit: 20, offset: 0))
      .handleEvents(receiveOutput: { response in
        do {
          let json = try JSON(data: response.data)
          try self.commit {
            try $0.db.performBatchUpdates { context in
              let items = try json.next("items").getArray().map { json in
                try Entities.Playlist(from: json, context: context)
              }
              let results = context.playlist.insert(items)
              context.indexes.playlistIndex.removeAll()

              context.indexes.playlistIndex.append(contentsOf: results.map { $0.entityID })
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


