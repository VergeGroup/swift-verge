//
//  HomeState.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/18.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import VergeNeue
import Combine

struct HomeState {
  
  var photos: [Photo] = []
}

final class HomeReducer: ModularReducerType {
  
  typealias TargetState = HomeState
  typealias ParentState = RootState
  
  private var subscriptions = Set<AnyCancellable>()
  
  let service: MockService
  
  init(service: MockService) {
    self.service = service
  }
  
  func parentChanged(newState: RootState) {
    print(newState)
  }
  
  func load() -> Action<Void> {
    return .init { context in
      
      self.service.fetchPhotosPage1()
        .sink(receiveCompletion: { (completion) in
          
        }) { (photos) in
          context.commit { _ in
            .init {
              $0.photos = photos
            }
          }
      }
      .store(in: &self.subscriptions)
      
    }
  }
  
}
