//
//  DemoState.swift
//  VergeStoreTests
//
//  Created by muukii on 2020/04/21.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import VergeStore

struct DemoState: ExtendedStateType {
  
  var name: String = ""
  
  struct Extended: ExtendedType {
    
    static let instance = Extended()
    
    let nameCount = Field.Computed<Int> {
      $0.name.count
    }
    .modified {
      $0.preFilter {
        $0.hasChanges(\.name)
      }
    }

  }
  
}
