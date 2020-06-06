
import Foundation
import VergeStore
import VergeORM

public struct Database: DatabaseType, Equatable {

  public struct Schema: EntitySchemaType {

    public init() {}

    public let artist = Entities.Artist.EntityTableKey()
    public let playlist = Entities.Playlist.EntityTableKey()
    public let me = Entities.Me.EntityTableKey()
    public let user = Entities.User.EntityTableKey()
  }

  public struct Indexes: IndexesType {

    public init() {}

    public let playlistIndex = IndexKey<OrderedIDIndex<Schema, Entities.Playlist>>()
  }

  public var _backingStorage: BackingStorage = .init()

}

public struct LoggedInBackendState: ExtendedStateType, Equatable, DatabaseEmbedding {

  public var db: Database = .init()

  public static var getterToDatabase: (LoggedInBackendState) -> Database {
    \.db
  }

  public struct Extended: ExtendedType {

    public static let instance: LoggedInBackendState.Extended = .init()

    public let me = Field.Computed.init(derive: \.db.entities.me) { (meTable) -> Entities.Me in
      meTable.allEntities().first!
    }
  }
}
