//
//  Notification.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/19.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

struct Notification: Identifiable {
  
  let id: UUID = UUID()
  let body: String
  
  init(body: String) {
    self.body = body
  }
}
