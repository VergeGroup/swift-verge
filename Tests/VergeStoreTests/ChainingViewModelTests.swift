//
//  ChainingViewModelTests.swift
//  VergeViewModelTests
//
//  Created by muukii on 2019/12/07.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import XCTest

import VergeStore

struct AViewModelState: StateType {
  var count: Int = 0
  var bViewModel: BViewModel?
}

final class AViewModel: StandaloneVergeViewModelBase<AViewModelState, Never> {
  
  init() {
    super.init(initialState: .init(), logger: nil)
    
    commit { $0.makeB() }
  }
  
  deinit {
    print("deinit", self)
  }
  
  func increment() -> Mutation<Void> {
    .mutation {
      $0.count += 1
    }
  }
  
  func makeB() -> Mutation<Void> {
    .mutation {
      $0.bViewModel = .init(viewModel: self)
    }
  }
  
 
}

struct BViewModelState: StateType {
  var count: Int = 0
}

final class BViewModel: ViewModelBase<ViewModelState, Never, AViewModelState, Never> {
  
  init(viewModel: AViewModel) {
    super.init(
      initialState: .init(),
      parent: viewModel,
      logger: nil
    )
  }
  
  override func updateState(state: inout ViewModelState, by parentState: AViewModelState) {
    state.count = parentState.count
  }
  
  deinit {
    print("deinit", self)
  }
}

final class ChainingViewModelTests: XCTestCase {
  
  func testChain() {
    
    let a: AViewModel? = AViewModel()
    a?.commit { $0.increment() }
    XCTAssertEqual(a!.state.bViewModel!.state.count, 1)
  }
}
