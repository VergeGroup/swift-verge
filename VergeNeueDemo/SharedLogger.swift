//
//  SharedLogger.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/18.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import VergeNeue

struct MyStoreLogger: StoreLogger {
  
  static let `default` = MyStoreLogger()
  
  func willCommit(store: Any, state: Any) {
    print("Will Commit", store, state)
  }
  
  func didCommit(store: Any, state: Any) {
    print("Did Commit", store, state)
  }
  
  func didDispatch(store: Any, state: Any) {
    print("Will Dispatch", store, state)
  }
      
}
