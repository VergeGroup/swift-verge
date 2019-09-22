//
//  PollingAdapter.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/22.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import Combine

import VergeNeue

final class PollingAdapter: AdapterBase<RootReducer> {
  
  private var bag = Set<AnyCancellable>()
  
  override init() {
    
    super.init()
    
    let p = Timer.TimerPublisher(interval: 5, runLoop: .main, mode: .default)
    p.connect().store(in: &bag)
    p
      .print()
      .sink { [weak self] _ in
      
      self?.run { store in
        store.commit { $0.syncIncrement() }
      }
    }
    .store(in: &bag)
  }
}
