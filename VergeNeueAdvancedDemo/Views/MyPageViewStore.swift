//
//  MyPageViewStore.swift
//  VergeNeueAdvancedDemo
//
//  Created by muukii on 2019/09/24.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import Combine

import VergeStore

struct MyPageViewState {
  
  var me: Me
}

final class MyPageViewStore: StoreBase<MyPageViewState> {
  
  private var bag: Set<AnyCancellable> = .init()
  
  init(service: Service) {
    
    super.init(initialState: .init(me: service.me), logger: MyStoreLogger.default)
    
    service.$me.sink { (newMe) in
      
    }
    .store(in: &bag)
  }
}
