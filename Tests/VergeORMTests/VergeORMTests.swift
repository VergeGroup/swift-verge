//
//  VergeNormalizerTests.swift
//  VergeNormalizerTests
//
//  Created by muukii on 2019/12/07.
//  Copyright © 2019 muukii. All rights reserved.
//

import XCTest

import VergeCore
import VergeORM

class VergeORMTests: XCTestCase {
  
  override func setUp() {
    // Put setup code here. This method is called before the invocation of each test method in the class.        
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
  
  func testCommit() {
    
    var state = RootState()
    
    let context = state.db.beginBatchUpdates()
    
    let book = Book(rawID: "some", authorID: Author.anonymous.entityID)
    context.book.insert(book)
    
    state.db.commitBatchUpdates(context: context)
    
    let a = state.db.entities.book
    let b = state.db.entities.book
    
    XCTAssertEqual(a, b)
    
  }
  
  func testEqualityEntityTable() {
    
    var state = RootState()
    
    state.db.performBatchUpdates { (context) in
      
      let book = Book(rawID: "some", authorID: Author.anonymous.entityID)
      context.book.insert(book)
    }
    
    let a = state.db.entities.book
    let b = state.db.entities.book
    
    XCTAssertEqual(a, b)
        
  }
  
  func testSimpleInsert() {
    
    var state = RootState()
    
    state.db.performBatchUpdates { (context) in
      
      let book = Book(rawID: "some", authorID: Author.anonymous.entityID)
      context.book.insert(book)
    }
    
    XCTAssertEqual(state.db.entities.book.count, 1)
    
  }
  
  func testManagingOrderTable() {
    
    var state = RootState()
    
    state.db.performBatchUpdates { (context) in
      
      let book = Book(rawID: "some", authorID: Author.anonymous.entityID)
      context.book.insert(book)
      context.indexes.allBooks.append(book.entityID)
    }
        
    XCTAssertEqual(state.db.entities.book.count, 1)
    XCTAssertEqual(state.db.indexes.allBooks.count, 1)
    
    print(state.db.indexes.allBooks)
    
    state.db.performBatchUpdates { (context) -> Void in
      context.book.deletes.insert(Book.EntityID.init("some"))
    }
    
    XCTAssertEqual(state.db.entities.book.count, 0)
    XCTAssertEqual(state.db.indexes.allBooks.count, 0)
    
  }
  
  func testUpdate() {
    
    var state = RootState()
    
    let id = Book.EntityID.init("some")
    
    state.db.performBatchUpdates { (context) in
      
      let book = Book(rawID: id.raw, authorID: Author.anonymous.entityID)
      context.book.insert(book)
    }
    
    XCTAssertNotNil(state.db.entities.book.find(by: id))
    
    state.db.performBatchUpdates { (context) in
            
      guard var book = context.book.current.find(by: id) else {
        XCTFail()
        return
      }
      book.name = "hello"
      
      context.book.insert(book)
    }
    
    XCTAssertNotNil(state.db.entities.book.find(by: id))
    XCTAssertNotNil(state.db.entities.book.find(by: id)!.name == "hello")

  }
  
  func testUpdateIfExists() {
    
    var state = RootState()
    
    state.db.performBatchUpdates { (context) -> Void in
      
      context.author.insert(Author(rawID: "muukii", name: "muukii"))
          
    }
    
    state.db.performBatchUpdates { context in
      
      context.author.updateIfExists(id: .init("muukii")) { (author) in
        XCTAssertEqual(author.name, "muukii")
        author.name = "Hiroshi"
      }
      
      context.author.updateIfExists(id: .init("muukii")) { (author) in
        XCTAssertEqual(author.name, "Hiroshi")
        author.name = "Kimura"
      }
      
      context.author.updateIfExists(id: .init("muukii")) { (author) in
        XCTAssertEqual(author.name, "Kimura")
      }
      
    }
    
  }
  
  func testGetAll() {
    
    var state = RootState()
    
    state.db.performBatchUpdates { (context) -> Void in
      
      context.author.insert(Author(rawID: "muukii", name: "muukii"))
      
    }
    
    state.db.performBatchUpdates { context in
      
      XCTAssertEqual(context.author.all().first?.name, "muukii")
      
      context.author.updateIfExists(id: .init("muukii")) { (author) in
        XCTAssertEqual(author.name, "muukii")
        author.name = "Hiroshi"
      }
            
      XCTAssertEqual(context.author.all().first?.name, "Hiroshi")
      
      context.author.updateIfExists(id: .init("muukii")) { (author) in
        XCTAssertEqual(author.name, "Hiroshi")
        author.name = "Kimura"
      }
      
      XCTAssertEqual(context.author.all().first?.name, "Kimura")
      
      context.author.updateIfExists(id: .init("muukii")) { (author) in
        XCTAssertEqual(author.name, "Kimura")
      }
      
    }
    
  }
  
  func testDescription() {
    
    let authorID = Author.EntityID("author.id")
    XCTAssertEqual(authorID.description, "<VergeORMTests.Author>(author.id)")
  }
  
  func testFind() {
    
    var state = RootState()
    
    state.db.performBatchUpdates { (context) -> Void in
      
      for i in 0..<100 {
        
        let a = Author(rawID: "\(i)", name: "\(i)")
        
        context.author.insert(a)
        context.book.insert(Book(rawID: "\(i)", authorID: a.entityID))
        
      }
            
    }
    
    XCTAssertNotNil(
      state.db.entities.book.find(by: .init("\(1)"))
    )
    
    XCTAssertEqual(
      state.db.entities.book.find(in: [.init("\(1)"), .init("\(2)")]).count,
      2
    )

    XCTAssertNotNil(
      state.db.entities.author.find(by: .init("\(1)"))
    )
    
    XCTAssertEqual(
      state.db.entities.author.find(in: [.init("\(1)"), .init("\(2)")]).count,
      2
    )
    
  }
  
}
