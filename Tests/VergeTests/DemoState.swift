

//
//  DemoState.swift
//  VergeStoreTests
//
//  Created by muukii on 2020/04/21.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation
import Verge
import XCTest
import Observation

struct NonEquatable: Sendable {
  let id = UUID()
}
struct OnEquatable: Equatable, Sendable {
  let id = UUID()
}

@Tracking
struct DemoState: Sendable {

  struct Inner: Equatable {
    var name: String = ""
  }

  var name: String = ""
  var count: Int = 0
  var items: [Int] = []
  var inner: Inner = .init()
  
  init() {
    
  }
  
  init(name: String) {
    self.name = name
  }
  
  init(name: String, count: Int) {
    self.name = name
    self.count = count
  }

  var nonEquatable: NonEquatable = .init()

  var onEquatable: OnEquatable = .init()
  
  var recursive: DemoState? = nil

  mutating func updateFromItself() {
    count += 1
  }

}

enum DemoActivity {
  case something
}

#if canImport(Verge)

import Verge

final class DemoStore: Verge.Store<DemoState, DemoActivity> {

  init() {
    super.init(initialState: .init(), logger: nil)
  }

  func increment() {
    commit {
      $0.count += 1
    }
  }

  func empty() {
    commit { _ in
    }
  }

}

#endif
