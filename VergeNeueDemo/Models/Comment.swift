//
//  Comment.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/19.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

struct Comment: Identifiable {
  
  let id: UUID = UUID()
  let photoID: Photo.ID
  let body: String
  
  init(photoID: Photo.ID, body: String) {
    self.photoID = photoID
    self.body = body
  }
  
}
