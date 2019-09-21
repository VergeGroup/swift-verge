//
//  Comment.swift
//  VergeNeueAdvancedDemo
//
//  Created by muukii on 2019/09/22.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import FlatStore
import CoreStore

final class Comment: CoreStoreObject {
  let rawID = Value.Required<String>("rawID", initial: "")
  let updatedAt = Value.Required<Date>("updatedAt", initial: Date())

  let issue = Relationship.ToOne<Issue>("issue", inverse: { $0.comments })
  
  let body = Value.Optional<String>("body")
}
