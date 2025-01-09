import VergeNormalization

struct Book: EntityType, Hashable {

  typealias TypedIdentifierRawValue = String

  var typedID: TypedID {
    .init(rawID)
  }

  let rawID: String
  let authorID: Author.TypedID
  var name: String = "initial"
}

struct Author: EntityType {

  typealias TypedIdentifierRawValue = String

  var typedID: TypedID {
    .init(rawID)
  }

  let rawID: String
  var name: String = ""

  static let anonymous: Author = .init(rawID: "anonymous")
}

@NormalizedStorage
struct MyStorage {

  @Table
  var book: Tables.Hash<Book> = .init()
  @Table
  var author: Tables.Hash<Author> = .init()

  @Index
  var bookIndex: Indexes.Ordered<Book> = .init()

}
