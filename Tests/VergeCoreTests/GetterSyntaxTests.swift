//
//  SyntaxTests.swift
//  VergeCoreTests
//
//  Created by muukii on 2020/02/01.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import XCTest

import VergeCore

@available(iOS 13, *)
final class GetterSyntaxTests: XCTestCase {
  
  struct State {
    var title: String = ""
    var count: Int = 0
  }
  
  private let store = Storage<State>(.init())
    
  func testGetterSyntax1() {
        
    let _ = store.makeGetter {
      $0.changed(keySelector: \.title, comparer: .init(==))
        .map(\.title)
    }
        
  }
  
  func testGetterSyntax2() {
    
    /// Projects State object into `count` with **NO** filter.
    
    let _ = store.makeGetter {
      $0.map(\.count)
    }
    
    /// Projects State object into `count` with filtering
    
    let _ = store.makeGetter {
      $0.map(\.count)
        .changed(comparer: .init(==))
    }
    
  }
  
  func testGetterSyntax3() {
    
    func pass(getter: Getter<Int>) {
      
    }
    
    let getter = store.makeGetter {
      $0.map(\.count)
    }
    
    pass(getter: getter)
    
  }
  
  func testGetterSubscribe() {
    
    let getter = store.makeGetter {
      $0.map(\.count)
    }
    
    getter.sink { (value) in
      
    }
    
  }

  
}
