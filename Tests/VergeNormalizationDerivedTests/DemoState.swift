import VergeNormalizationDerived

struct DemoState: Equatable {

  var count: Int = 0

  var db: Database = .init()

  struct DatabaseSelector: StorageSelector {
    typealias Source = DemoState
    typealias Storage = Database

    func select(source: consuming DemoState) -> Database {
      source.db
    }
  }
}

@NormalizedStorage
struct Database {

  @Table
  var book: Tables.Hash<Book> = .init()

  @Table
  var author: Tables.Hash<Author> = .init()

}

extension Database {

}

struct Book: EntityType, Hashable {

  typealias EntityIDRawType = String

  var entityID: EntityID {
    .init(rawID)
  }

  let rawID: String
  let authorID: Author.EntityID
  var name: String = "initial"
}

struct Author: EntityType {

  typealias EntityIDRawType = String

  var entityID: EntityID {
    .init(rawID)
  }

  let rawID: String
  var name: String = ""

  static let anonymous: Author = .init(rawID: "anonymous")
}
