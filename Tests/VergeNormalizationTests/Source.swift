import VergeNormalization
import XCTest

final class Tests: XCTestCase {

  func test_insert() {

    var storage = MyStorage()

    storage.performBatchUpdates { t in
      t.modifying.author.insert(.init(rawID: "M"))
    }

    XCTAssertEqual(storage.author.count, 1)

  }

  func test_init_count() {

    let db = MyStorage()
    XCTAssertEqual(db.book.allEntities().count, 0)
  }

  func testCommit() {

    var state = MyStorage()

    var transaction = state.beginBatchUpdates()

    let book = Book(rawID: "some", authorID: Author.anonymous.typedID)
    transaction.modifying.book.insert(book)

    state.commitBatchUpdates(transaction: transaction)

    let a = state.book
    let b = state.book

    XCTAssertEqual(a, b)

  }

  func testEqualityEntityTable() {

    var state = MyStorage()

    state.performBatchUpdates { (context) in

      let book = Book(rawID: "some", authorID: Author.anonymous.typedID)
      context.modifying.book.insert(book)
    }

    let a = state.book
    let b = state.book

    XCTAssertEqual(a, b)

  }

  func testSimpleInsert() {

    var state = MyStorage()

    state.performBatchUpdates { (context) in

      let book = Book(rawID: "some", authorID: Author.anonymous.typedID)
      context.modifying.book.insert(book)
    }

    XCTAssertEqual(state.book.count, 1)

  }

  func testManagingOrderTable() {

    var state = MyStorage()

    state.performBatchUpdates { (context) in

      let book = Book(rawID: "some", authorID: Author.anonymous.typedID)
      context.modifying.book.insert(book)
      context.modifying.bookIndex.append(book.typedID)
    }

    XCTAssertEqual(state.book.count, 1)
    XCTAssertEqual(state.bookIndex.count, 1)

    print(state.bookIndex)

    state.performBatchUpdates { (context) -> Void in
      context.modifying.book.remove(Book.TypedID.init("some"))
    }

    XCTAssertEqual(state.book.count, 0)

    /// should not be deleted automatically
    XCTAssertEqual(state.bookIndex.count, 1)

  }

  func testUpdate() {

    var state = MyStorage()

    let id = Book.TypedID.init("some")

    state.performBatchUpdates { (context) in

      let book = Book(rawID: id.raw, authorID: Author.anonymous.typedID)
      context.modifying.book.insert(book)
    }

    XCTAssertNotNil(state.book.find(by: id))

    state.performBatchUpdates { (context) in

      guard var book = context.modifying.book.find(by: id) else {
        XCTFail()
        return
      }
      book.name = "hello"

      context.modifying.book.insert(book)
    }

    XCTAssertNotNil(state.book.find(by: id))
    XCTAssertNotNil(state.book.find(by: id)!.name == "hello")

  }

  func testUpdateIfExists() {

    var state = MyStorage()

    state.performBatchUpdates { (context) -> Void in

      context.modifying.author.insert(Author(rawID: "muukii", name: "muukii"))

    }

    state.performBatchUpdates { context in

      context.modifying.author.updateIfExists(id: .init("muukii")) { (author) in
        XCTAssertEqual(author.name, "muukii")
        author.name = "Hiroshi"
      }

      context.modifying.author.updateIfExists(id: .init("muukii")) { (author) in
        XCTAssertEqual(author.name, "Hiroshi")
        author.name = "Kimura"
      }

      context.modifying.author.updateIfExists(id: .init("muukii")) { (author) in
        XCTAssertEqual(author.name, "Kimura")
      }

    }

  }

  func testGetAll() {

    var state = MyStorage()

    state.performBatchUpdates { (context) -> Void in

      context.modifying.author.insert(Author(rawID: "muukii", name: "muukii"))

    }

    state.performBatchUpdates { context in

      XCTAssertEqual(context.modifying.author.allEntities().first?.name, "muukii")

      context.modifying.author.updateIfExists(id: .init("muukii")) { (author) in
        XCTAssertEqual(author.name, "muukii")
        author.name = "Hiroshi"
      }

      XCTAssertEqual(context.modifying.author.allEntities().first?.name, "Hiroshi")

      context.modifying.author.updateIfExists(id: .init("muukii")) { (author) in
        XCTAssertEqual(author.name, "Hiroshi")
        author.name = "Kimura"
      }

      XCTAssertEqual(context.modifying.author.allEntities().first?.name, "Kimura")

      context.modifying.author.updateIfExists(id: .init("muukii")) { (author) in
        XCTAssertEqual(author.name, "Kimura")
      }

    }

  }

  func testDescription() {

    let authorID = Author.TypedID("author.id")
    XCTAssertEqual(authorID.description, "<VergeNormalizationTests.Author>(author.id)")
  }

  func testFind() {

    var state = MyStorage()

    state.performBatchUpdates { (context) -> Void in

      for i in 0..<100 {

        let a = Author(rawID: "\(i)", name: "\(i)")

        context.modifying.author.insert(a)
        context.modifying.book.insert(Book(rawID: "\(i)", authorID: a.typedID))

      }

    }

    XCTAssertNotNil(
      state.book.find(by: .init("\(1)"))
    )

    XCTAssertEqual(
      state.book.find(in: [.init("\(1)"), .init("\(2)")]).count,
      2
    )

    XCTAssertNotNil(
      state.author.find(by: .init("\(1)"))
    )

    XCTAssertEqual(
      state.author.find(in: [.init("\(1)"), .init("\(2)")]).count,
      2
    )

  }

  func testDeletionAndInsertionInTransaction() {

    var state = MyStorage()

    let record = Author(rawID: "1", name: "1")

    state.performBatchUpdates { (context) -> Void in
      context.modifying.author.insert(record)
    }

    XCTAssertEqual(
      state.author.allEntities().count,
      1
    )

    state.performBatchUpdates { (context) -> Void in
      context.modifying.author.removeAll()
      context.modifying.author.insert(record)
    }

    XCTAssertEqual(
      state.author.allEntities().count,
      1
    )

    state.performBatchUpdates { (context) -> Void in
      context.modifying.author.removeAll()
      context.modifying.author.insert([record])
    }

    XCTAssertEqual(
      state.author.allEntities().count,
      1
    )

  }


}
