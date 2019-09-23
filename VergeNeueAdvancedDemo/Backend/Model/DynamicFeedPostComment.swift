//
//  Comment.swift
//  VergeNeueAdvancedDemo
//
//  Created by muukii on 2019/09/22.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import CoreStore

/// CoreData Object (NSManagedObject)
final class DynamicFeedPostComment: CoreStoreObject, Identifiable {
    
  var id: String {
    return rawID.value
  }
  
  let rawID = Value.Required<String>("rawID", initial: "")
  let updatedAt = Value.Required<Date>("updatedAt", initial: Date())

  let post = Relationship.ToOne<DynamicFeedPost>("issue", inverse: { $0.comments })
  
  let body = Value.Optional<String>("body")
}
