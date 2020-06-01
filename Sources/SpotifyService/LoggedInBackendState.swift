
import Foundation
import VergeStore
import VergeORM

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

public struct LoggedInBackendState: ExtendedStateType, Equatable, DatabaseEmbedding {

  let auth: AuthResponse
  var db: Database = .init()

  public static var getterToDatabase: (LoggedInBackendState) -> Database {
    \.db
  }

  init(auth: AuthResponse) {
    self.auth = auth
  }

  public struct Extended: ExtendedType {

    public static let instance: LoggedInBackendState.Extended = .init()

    public let me = Field.Computed.init(derive: \.db.entities.me) { (meTable) -> Entities.Me in
      meTable.allEntities().first!
    }
  }
}
