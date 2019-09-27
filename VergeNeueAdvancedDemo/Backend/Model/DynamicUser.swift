//
//  User.swift
//  VergeNeueAdvancedDemo
//
//  Created by muukii on 2019/09/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import CoreStore

/// CoreData Object (NSManagedObject)
final class DynamicUser: CoreStoreObject {
  let rawID = Value.Required<String>("rawID", initial: "")
  let updatedAt = Value.Required<Date>("updatedAt", initial: Date())
  let name = Value.Required<String>("name", initial: "")
  let posts = Relationship.ToManyUnordered<DynamicFeedPost>("posts")
}

struct SnapshotUser: Identifiable {
  
  var id: String
  var updatedAt: Date
  var name: String
  var postIDs: [SnapshotFeedPost.ID]
  
  init(source: DynamicUser) {
    self.id = source.rawID.value
    self.updatedAt = source.updatedAt.value
    self.name = source.name.value
    self.postIDs = source.posts.value.map { $0.rawID.value }
  }
}
