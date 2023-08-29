import VergeNormalization

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

@NormalizedStorage
struct MyStorage {

  var book: Table<Book> = .init()
  var author: Table<Author> = .init()

}
