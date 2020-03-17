//
//  MultithreadingTests.swift
//  VergeORM
//
//  Created by muukii on 2020/03/17.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import XCTest

import VergeStore
import VergeORM

class MultithreadingTests: XCTestCase {
  
  let store = Storage(RootState())
      
  func testUpdateFromThreads() {
    
    for _ in 0..<20 {
      
      DispatchQueue.global().async {
        self.store.update { state in
          state.db.performBatchUpdates { (context) in
            
            let authors = (0..<1000).map { i in
              Author(rawID: "author.\(i)")
            }
            context.author.insert(authors)
          }
        }
      }
    }
                    
  }
}
