//
//  VergeViewModelTests.swift
//  VergeViewModelTests
//
//  Created by muukii on 2019/11/24.
//  Copyright © 2019 muukii. All rights reserved.
//

import XCTest

import VergeStore

class VergeViewModelTests: XCTestCase {
  
  struct RootState: StateType {
    var count: Int = 0
  }
  
  final class RootStore: StoreBase<RootState, Never> {
    
  }
  
  final class RootDispatcher: RootStore.Dispatcher {
    
    func increment() {
      commit {
        $0.count += 1
      }
    }
  }
  
  struct MyViewModelState: StateType {
    var rootCount: Int = 0
    var count: Int = 0
  }
  
  final class MyViewModel: ViewModelBase<MyViewModelState, Never, RootState, Never> {
    
    override func updateState(state: inout MyViewModelState, by parentState: RootState) {
      state.rootCount = parentState.count
    }
    
    func increment() {
      commit {
        $0.count += 1
      }
    }
  }
    
  let store = RootStore(initialState: .init(), logger: DefaultStoreLogger.shared)
  lazy var dispatcher = RootDispatcher(target: store)
  lazy var viewModel = MyViewModel(initialState: .init(), parent: store, logger: DefaultStoreLogger.shared)
    
  override func setUp() {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    _ = viewModel
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
  
  func testSyncRootStore() {
    dispatcher.increment()
    XCTAssertEqual(viewModel.state.rootCount, 1)
  }
  
  func testIncrement() {
    
    viewModel.increment()
    XCTAssertEqual(viewModel.state.count, 1)

  }
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    measure {
      // Put the code you want to measure the time of here.
    }
  }
  
}
