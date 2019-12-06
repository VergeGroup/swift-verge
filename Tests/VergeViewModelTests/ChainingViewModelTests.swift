//
//  ChainingViewModelTests.swift
//  VergeViewModelTests
//
//  Created by muukii on 2019/12/07.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import XCTest

import VergeViewModel

struct AViewModelState {
  var count: Int = 0
  var bViewModel: BViewModel?
}

final class AViewModel: StandaloneVergeViewModelBase<AViewModelState> {
  
  init() {
    super.init(initialState: .init(), logger: nil)
    
    commit.makeB()
  }
  
  deinit {
    print("deinit", self)
  }
}

extension Mutations where Base : AViewModel {
  
  func increment() {
    descriptor.commit {
      $0.count += 1
    }
  }
  
  func makeB() {
    descriptor.commit {
      $0.bViewModel = .init(viewModel: base)
    }
  }
  
 
}

struct BViewModelState {
  var count: Int = 0
}

final class BViewModel: VergeViewModelBase<ViewModelState, AViewModelState> {
  
  init(viewModel: AViewModel) {
    super.init(
      initialState: .init(),
      parent: viewModel,
      logger: nil
    )
  }
  
  override func updateState(state: inout ViewModelState, by storeState: AViewModelState) {
    state.count = storeState.count
  }
  
  deinit {
    print("deinit", self)
  }
}

final class ChainingViewModelTests: XCTestCase {
  
  func testChain() {
    
    let a: AViewModel? = AViewModel()
    a?.commit.increment()
    XCTAssertEqual(a!.state.bViewModel!.state.count, 1)
  }
}
