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
  
  private let storage = Storage<State>(.init())
    
  func testGetterSyntax1() {
    
    let _ = storage.makeGetter {
      $0.preFilter(keySelector: \.title, comparer: .init(==))
        .map(\.title)
    }
        
  }
  
  func testGetterSyntax2() {
    
    /// Projects State object into `count` with **NO** filter.
    
    let _ = storage.makeGetter {
      $0.map(\.count)
    }
    
    /// Projects State object into `count` with filtering
    
    let _ = storage.makeGetter {
      $0.map(\.count)
        .postFilter(comparer: .init(==))
    }
    
  }

  
}
