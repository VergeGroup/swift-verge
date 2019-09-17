//
//  MockAPIProvider.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/18.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation
import Combine
import JAYSON

final class MockAPIProvider {
  
  private let queue = DispatchQueue.global(qos: .default)
  
  init() {
    
  }
  
  func fetchPhotos() -> Future<JSON, Never> {
    .init { promise in
      demoDelay(on: self.queue) {
        
        let data = try! Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "list_page_1", ofType: "json")!))
                        
        promise(.success(try! JSON(data: data)))
      }
    }
  }
  
}
