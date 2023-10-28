import VergeNormalizationDerived

struct DemoState: StateType {

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

extension StorageSelector where Self == DemoState.DatabaseSelector {
  static var db: Self {
    DemoState.DatabaseSelector()
  }
}

@NormalizedStorage
struct Database {

  @Table
  var book: Tables.Hash<Book> = .init()

  @Table
  var book2: Tables.Hash<Book> = .init()

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
