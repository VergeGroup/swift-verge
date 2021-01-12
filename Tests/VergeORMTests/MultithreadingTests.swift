//
//  MultithreadingTests.swift
//  VergeORM
//
//  Created by muukii on 2020/03/17.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import XCTest

import Verge
import VergeORM

class MultithreadingTests: XCTestCase {
  
  let store = Storage(RootState())
      
  func testUpdateFromThreads() {
    
    let exp = expectation(description: "")
    
    let g = DispatchGroup()
    
    for _ in 0..<20 {
      
      g.enter()
      DispatchQueue.global().async {
        self.store.update { state in
          state.db.performBatchUpdates { (context) in
            
            let authors = (0..<1000).map { i in
              Author(rawID: "author.\(i)")
            }
            context.entities.author.insert(authors)
          }
        }
        g.leave()
      }
    }
    
    g.notify(queue: .main) {
      exp.fulfill()
    }
    
    wait(for: [exp], timeout: 10)
                    
  }
  
  
  func testUpdateFromThreads2() {
    
    measure {
      DispatchQueue.concurrentPerform(iterations: 1000) { (i) in
        self.store.update { state in
          state.other.count += 1
        }
      }
    }
    
  }
  
  func testUpdateFromThreads3() {
    
    measure {
      DispatchQueue.concurrentPerform(iterations: 1000) { (i) in
        self.store.update { state in
          state.db.performBatchUpdates { (context) in
            let authors = (0..<40).map { i in
              Author(rawID: "author.\(i)")
            }
            context.entities.author.insert(authors)
          }
        }
      }
    }
    
  }
}
