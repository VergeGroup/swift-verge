import Foundation

import JAYSON
import Moya
import VergeStore
import Combine
import CombineExt
import VergeORM

extension MoyaProvider {

  func requestPublisher(_ target: Target) -> AnyPublisher<Response, MoyaError> {
    return .init { (s) in
      let cancellable = self.request(target) { (result) in
        switch result {
        case .success(let response):
          do {
            let response = try response.filterSuccessfulStatusAndRedirectCodes()
            s.send(response)
          } catch let error as MoyaError {
            s.send(completion: .failure(error))
          } catch {
            assertionFailure()
          }
        case .failure(let error):
          s.send(completion: .failure(error))
        }
      }
      return AnyCancellable {
        cancellable.cancel()
      }
    }
  }

}

extension Publisher {

  @discardableResult
  func start() -> Future<Output, Failure> {
    return .init { promise in

      var cancellableRef: Unmanaged<AnyCancellable>? = nil

      let c = self.sink(receiveCompletion: { (completion) in
        switch completion {
        case .failure(let error):
          promise(.failure(error))
          cancellableRef?.release()
        case .finished:
          break
        }
      }) { (value) in
        promise(.success(value))
        cancellableRef?.release()
      }

      cancellableRef = Unmanaged.passRetained(c)
    }
  }
}

public struct Database: DatabaseType, Equatable {

  public struct Schema: EntitySchemaType {

    public init() {}

    public let artists = Entities.Artist.EntityTableKey()
    public let me = Entities.Me.EntityTableKey()
  }

  public struct Indexes: IndexesType {

    public init() {}
  }

  public var _backingStorage: BackingStorage = .init()

}

public struct LoggedInServiceState: ExtendedStateType, Equatable, DatabaseEmbedding {

  let auth: AuthResponse
  var db: Database = .init()

  public static var getterToDatabase: (LoggedInServiceState) -> Database {
    \.db
  }
  
  init(auth: AuthResponse) {
    self.auth = auth
  }

  public struct Extended: ExtendedType {

    public static let instance: LoggedInServiceState.Extended = .init()

    public let me = Field.Computed.init(derive: \.db.entities.me) { (meTable) -> Entities.Me in
      meTable.allEntities().first!
    }
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


public final class LoggedInStack {

  public let service: LoggedInService
  
  init(store: BackendStore) {

    self.service = .init(targetStore: store)
    
  }
}
