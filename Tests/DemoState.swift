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

struct DemoState: StateType, Sendable {

  struct Inner: Equatable {
    var name: String = ""
  }

  var name: String = ""
  var count: Int = 0
  var items: [Int] = []
  var inner: Inner = .init()

  @Edge var nonEquatable: NonEquatable = .init()

  @Edge var onEquatable: OnEquatable = .init()

  mutating func updateFromItself() {
    count += 1
  }

  @Sendable
  static func reduce(
    modifying: inout Self,
    current: Changes<Self>,
    transaction: inout Transaction
  ) {}
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
