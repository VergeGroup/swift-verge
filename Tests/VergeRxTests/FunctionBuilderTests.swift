//
//  FunctionBuilderTests.swift
//  VergeRxTests
//
//  Created by muukii on 2020/01/28.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import VergeRx
import RxSwift

enum FunctionBuilderTests {
  
  static func test() {
    
    _ = SubscriptionGroup {
      
      Single.just(1).subscribe()
      
    }
    
    _ = SubscriptionGroup {
      
      Single.just(1).subscribe()
      Single.just(1).subscribe()
            
    }
    
    _ = SubscriptionGroup {
      [
      Single.just(1).subscribe(),
      Single.just(1).subscribe()
      ]
    }
    
  }
}
