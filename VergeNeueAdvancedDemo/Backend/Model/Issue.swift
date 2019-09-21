//
//  Issue.swift
//  VergeNeueAdvancedDemo
//
//  Created by muukii on 2019/09/22.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import FlatStore
import CoreStore

final class Issue: CoreStoreObject {
  let rawID = Value.Required<String>("rawID", initial: "")
  let updatedAt = Value.Required<Date>("updatedAt", initial: Date())
  let title = Value.Optional<String>("title")
  let body = Value.Optional<String>("body")
  
  let comments = Relationship.ToManyUnordered<Comment>("comments")
}
