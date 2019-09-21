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
  
  func willCommit(store: Any, state: Any, mutation: MutationMetadata) {
    print("Will Commit", store, mutation)
  }
  
  func didCommit(store: Any, state: Any, mutation: MutationMetadata) {
    print("Did Commit", store, mutation)
  }
  
  func didDispatch(store: Any, state: Any, action: ActionMetadata) {
    print("Will Dispatch", store, action)
  }
      
}
