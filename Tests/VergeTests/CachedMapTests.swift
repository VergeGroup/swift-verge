//
//  CachedMapTests.swift
//  VergeStoreTests
//
//  Created by muukii on 2020/07/25.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import XCTest
import Verge

final class CachedMapTests: XCTestCase {

  struct Entity {
    let id: String
  }
    
  final class ViewModel: Equatable {

    static func == (lhs: ViewModel, rhs: ViewModel) -> Bool {
      lhs === rhs
    }

    init(entity: Entity) {
    }
  }
    
  func testCacheAvailability() {    
    
    let storage = InstancePool<Entity, ViewModel>.init(keySelector: \.id)

    let fetchedEntities: [Entity] = (0..<100).map { Entity(id: $0.description) }

    let resultA = fetchedEntities.cachedMap(using: storage, sweepsUnused: true, makeNew: {
      ViewModel(entity: $0)
    })

    let resultB = fetchedEntities.cachedMap(using: storage, sweepsUnused: true, makeNew: {
      XCTFail()
      return ViewModel(entity: $0)
    })

    XCTAssertEqual(resultA, resultB)
  }
 
}
