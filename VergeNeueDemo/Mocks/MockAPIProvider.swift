//
//  MockAPIProvider.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/18.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation
import Combine

final class MockAPIProvider {
  
  init() {
    
  }
  
  func fetchPhotos() -> Future<[Photo], Never> {
    .init { promise in
      demoDelay {
        promise(.success([]))
      }
    }
  }
  
}
