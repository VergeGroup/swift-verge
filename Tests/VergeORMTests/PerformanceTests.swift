//
//  PerformanceTests.swift
//  VergeORMTests
//
//  Created by muukii on 2019/12/17.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation
import XCTest
import Verge

@available(iOS 13.0, *)
final class PerformanceTests: XCTestCase {

  var state = RootState()

  func testReflectionObjectIdentifier() {
    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      _ = ObjectIdentifier(Author.self)
    }
  }

  func testReflectionString() {
    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      _ = String(reflecting: Author.self)
    }
  }

  func testUpdateFindAndStore() {

    state.db.performBatchUpdates { (context) in

      let authors = (0..<10000).map { i in
        Author(rawID: "author.\(i)")
      }
      context.entities.author.insert(authors)
    }

    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      state.db.performBatchUpdates { context in
        var author = context.entities.author.current.find(by: .init("author.100"))!
        author.name = "mmm"
        context.entities.author.insert(author)
      }
    }

  }

  func testUpdateInline() {

    state.db.performBatchUpdates { (context) in

      let authors = (0..<10000).map { i in
        Author(rawID: "author.\(i)")
      }
      context.entities.author.insert(authors)
    }

    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      state.db.performBatchUpdates { context -> Void in
        context.entities.author.updateIfExists(id: .init("author.100")) { (author) in
          author.name = "mmm"
        }
      }
    }

  }

  func testInsertMany() {

    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      state.db.performBatchUpdates { (context) in

        let authors = (0..<10000).map { i in Author(rawID: "author.\(i)") }
        context.entities.author.insert(authors)

      }
    }

  }

  func testInsert3000() {

    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      state.db.performBatchUpdates { (context) in

        for i in 0..<3000 {
          let author = Author(rawID: "author.\(i)")
          context.entities.author.insert(author)
        }

      }
    }

  }

  func testInsert3000UseCollection() {

    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      state.db.performBatchUpdates { (context) in

        let authors = (0..<3000).map { i in
          Author(rawID: "author.\(i)")
        }

        context.entities.author.insert(authors)

      }
    }

  }

  func testInsert10000UseCollection() {

    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      state.db.performBatchUpdates { (context) in

        let authors = (0..<10000).map { i in
          Author(rawID: "author.\(i)")
        }

        context.entities.author.insert(authors)

      }
    }

  }

  func testInsert100000UseCollection() {

    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      state.db.performBatchUpdates { (context) in

        let authors = (0..<100000).map { i in
          Author(rawID: "author.\(i)")
        }

        context.entities.author.insert(authors)

      }
    }

  }

  func testInsertToFatStore() {

    state.db.performBatchUpdates { (context) in
      let authors = (0..<1000).map { i in
        Author(rawID: "author.\(i)")
      }

      context.entities.author.insert(authors)
    }

    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      state.db.performBatchUpdates { (context) in

        let authors = (0..<1000).map { i in
          Author(rawID: "author.\(i)")
        }

        context.entities.author.insert(authors)

      }
    }

  }

  func testInsertSoManySeparatedTransaction() {

    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      for l in 0..<10 {
        state.db.performBatchUpdates { (context) in

          for i in 0..<1000 {
            let author = Author(rawID: "author.\(l)-\(i)")
            context.entities.author.insert(author)
          }

        }
      }
    }

  }

  func testInsertManyEachTransaction() {
    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      /// O(n^2)
      for i in 0..<10 {
        state.db.performBatchUpdates { (context) in
          let author = Author(rawID: "author.\(i)")
          context.entities.author.insert(author)
        }

      }
    }
  }

}

final class FindPerformanceTests: XCTestCase {

  var state = RootState()

  override func setUp() {
    state.db.performBatchUpdates { (context) -> Void in

      context.entities.author.insert(
        (0..<10000).map { i in
          Author(rawID: "author.\(i)")
        }
      )

    }
  }

  func testFindOne() {

    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      _ = state.db.entities.author.find(by: .init("author.199"))
    }

  }

  func testFindMultiple() {

    let ids = Set<Author.EntityID>([
      .init("author.11"),
      .init("author.199"),
      .init("author.399"),
    ])

    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      _ = state.db.entities.author.find(in: ids)
    }

  }

}

final class ModifyPerformanceTests: XCTestCase {

  var state = RootState()

  override func setUp() {
    state.db.performBatchUpdates { (context) -> Void in

      context.entities.author.insert(
        (0..<10000).map { i in
          Author(rawID: "author.\(i)")
        }
      )

    }
  }

}

final class DictionaryPerformanceTests: XCTestCase {

  struct Concrete {

    var id: Int

    let value_0: Int64 = 1
    let value_1: Int64 = 1
    let value_2: Int64 = 1
    let value_3: Int64 = 1
    let value_4: Int64 = 1
    let value_5: Int64 = 1
    let value_6: Int64 = 1
    let value_7: Int64 = 1
    let value_8: Int64 = 1
    let value_9: Int64 = 1
    let value_10: Int64 = 1
    let value_11: Int64 = 1
    let value_12: Int64 = 1
    let value_13: Int64 = 1
    let value_14: Int64 = 1
    let value_15: Int64 = 1
    let value_16: Int64 = 1
    let value_17: Int64 = 1
    let value_18: Int64 = 1
    let value_19: Int64 = 1
    let value_20: Int64 = 1
    let value_21: Int64 = 1
    let value_22: Int64 = 1
    let value_23: Int64 = 1
    let value_24: Int64 = 1
    let value_25: Int64 = 1
    let value_26: Int64 = 1
    let value_27: Int64 = 1
    let value_28: Int64 = 1
    let value_29: Int64 = 1
    let value_30: Int64 = 1
    let value_31: Int64 = 1
    let value_32: Int64 = 1
    let value_33: Int64 = 1
    let value_34: Int64 = 1
    let value_35: Int64 = 1
    let value_36: Int64 = 1
    let value_37: Int64 = 1
    let value_38: Int64 = 1
    let value_39: Int64 = 1
    let value_40: Int64 = 1
    let value_41: Int64 = 1
    let value_42: Int64 = 1
    let value_43: Int64 = 1
    let value_44: Int64 = 1
    let value_45: Int64 = 1
    let value_46: Int64 = 1
    let value_47: Int64 = 1
    let value_48: Int64 = 1
    let value_49: Int64 = 1
    let value_50: Int64 = 1
    let value_51: Int64 = 1
    let value_52: Int64 = 1
    let value_53: Int64 = 1
    let value_54: Int64 = 1
    let value_55: Int64 = 1
    let value_56: Int64 = 1
    let value_57: Int64 = 1
    let value_58: Int64 = 1
    let value_59: Int64 = 1
    let value_60: Int64 = 1
    let value_61: Int64 = 1
    let value_62: Int64 = 1
    let value_63: Int64 = 1
    let value_64: Int64 = 1
    let value_65: Int64 = 1
    let value_66: Int64 = 1
    let value_67: Int64 = 1
    let value_68: Int64 = 1
    let value_69: Int64 = 1
    let value_70: Int64 = 1
    let value_71: Int64 = 1
    let value_72: Int64 = 1
    let value_73: Int64 = 1
    let value_74: Int64 = 1
    let value_75: Int64 = 1
    let value_76: Int64 = 1
    let value_77: Int64 = 1
    let value_78: Int64 = 1
    let value_79: Int64 = 1
    let value_80: Int64 = 1
    let value_81: Int64 = 1
    let value_82: Int64 = 1
    let value_83: Int64 = 1
    let value_84: Int64 = 1
    let value_85: Int64 = 1
    let value_86: Int64 = 1
    let value_87: Int64 = 1
    let value_88: Int64 = 1
    let value_89: Int64 = 1
    let value_90: Int64 = 1
    let value_91: Int64 = 1
    let value_92: Int64 = 1
    let value_93: Int64 = 1
    let value_94: Int64 = 1
    let value_95: Int64 = 1
    let value_96: Int64 = 1
    let value_97: Int64 = 1
    let value_98: Int64 = 1
    let value_99: Int64 = 1
  }

  class Ref {
    var base: Any

    init(_ base: Any) {
      self.base = base
    }
  }

  @available(iOS 13, *)
  func testModify() {

    let base = (0..<100000).reduce(into: [Int: Any]()) { partialResult, i in
      partialResult[i] = Concrete(id: i) as Any
    }

    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      for _ in (0..<100) {
        var copy = base
        copy[4] = Concrete(id: 4)
      }
    }

  }

  @available(iOS 13, *)
  func testModify_withBox() {

    let base = (0..<100000).reduce(into: [Int: Ref]()) { partialResult, i in
      partialResult[i] = .init(Concrete(id: i))
    }

    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {

      for _ in (0..<100) {
        var copy = base
        copy[4] = .init(Concrete(id: 4))
      }
    }

  }
  
  @available(iOS 13, *)
  func testModify_withCOWBox() {
    
    let base = (0..<100000).reduce(into: [Int: ReferenceEdge<Any>]()) { partialResult, i in
      partialResult[i] = .init(wrappedValue: Concrete(id: i))
    }
    
    measure(metrics: [XCTMemoryMetric(), XCTCPUMetric(), XCTClockMetric()]) {
      
      for _ in (0..<100) {
        var copy = base
        copy[4] = .init(wrappedValue: Concrete(id: 4))
      }
    }
    
  }

}
