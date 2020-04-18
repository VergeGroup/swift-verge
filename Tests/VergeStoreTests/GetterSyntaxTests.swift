//
//  SyntaxTests.swift
//  VergeCoreTests
//
//  Created by muukii on 2020/02/01.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import XCTest

import VergeStore

@available(iOS 13, *)
final class GetterSyntaxTests: XCTestCase {
  
  struct State: StateType {
    var title: String = ""
    var count: Int = 0
  }
  
  private let store = Store<State, Never>.init(initialState: .init(), logger: nil)
    
  func testGetterSyntax1() {
    
    let _: GetterSource<State, String> = store.getterBuilder()
      .changed(selector: \.title, comparer: .init(==))
      .map(\.title)
      .build()
                   
  }
  
  func testGetterSyntax2() {
    
    /// Projects State object into `count` with **NO** filter.
    
    let _: GetterSource<State, Int> = store.getterBuilder()
      .mapWithoutPreFilter(\.count)
      .build()
      
    
    /// Projects State object into `count` with filtering
    
    let _: GetterSource<State, Int> = store.getterBuilder()
      .mapWithoutPreFilter(\.count)
      .changed(comparer: .init(==))
      .build()
        
  }
  
  func testGetterSyntax3() {
    
    func pass(getter: Getter<Int>) {
      
    }
    
    let getter = store.getterBuilder()
      .mapWithoutPreFilter(\.count)
      .build()
    
    pass(getter: getter)
    
  }
  
  func testGetterSubscribe() {
    
    let getter = store.getterBuilder()
      .mapWithoutPreFilter(\.count)
      .build()
    
    _ = getter.sink { (value) in
      
    }
    
  }

  
}
