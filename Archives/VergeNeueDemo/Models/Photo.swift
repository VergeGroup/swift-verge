//
//  Photo.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/18.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation
import JAYSON

struct Photo: Identifiable {
  
  let id: String
  let url: URL
  
  init(from json: JSON) throws {
    
    self.id = try json.next("id").getString()
    self.url = try json.next("urls").next("regular").get {
      try URL(string: $0.getString())!
    }
  }
}
