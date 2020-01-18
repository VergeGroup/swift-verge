//
//  StandaloneVergeViewModel.swift
//  VergeViewModelTests
//
//  Created by muukii on 2019/12/05.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import XCTest

import VergeStore

struct ViewModelState: StateType {
  var count: Int = 0
}

final class ViewModel: StandaloneVergeViewModelBase<ViewModelState, Never> {

  init() {
    super.init(initialState: .init(), logger: nil)
  }
  
  func increment() {
    commit {
      $0.count += 1
    }
  }
}

final class StandaloneVergeViewModelTests: XCTestCase {
  
  func testMeasureMultithreading() {
    
    let viewModel = ViewModel()
    measure {
      DispatchQueue.concurrentPerform(iterations: 1000) { (_) in
        viewModel.increment()
      }
    }
              
  }
  
  func testMultithreading() {
    
    let viewModel = ViewModel()
    DispatchQueue.concurrentPerform(iterations: 1000) { (_) in
      viewModel.increment()
    }
    XCTAssertEqual(viewModel.state.count, 1000)
    
  }
}
