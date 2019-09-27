//
//  Issue.swift
//  VergeNeueAdvancedDemo
//
//  Created by muukii on 2019/09/22.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import CoreStore

/// CoreData Object (NSManagedObject)
final class DynamicFeedPost: CoreStoreObject {
    
  let rawID = Value.Required<String>("rawID", initial: "")
  let updatedAt = Value.Required<Date>("updatedAt", initial: Date())
  let imageURLString = Value.Required<String>("imageURLString", initial: "")
  
  let comments = Relationship.ToManyUnordered<DynamicFeedPostComment>("comments")
  let user = Relationship.ToOne<DynamicUser>("user", inverse: { $0.posts })
  
  var snapshotID: SnapshotFeedPost.ID {
    rawID.value
  }
}

struct SnapshotFeedPost: Equatable, Identifiable {
  
  var id: String
  var updatedAt: Date
  var imageURLString: String
  var commentIDs: [SnapshotFeedPostComment.ID]
  var userID: SnapshotUser.ID?
  var managedObjectID: NSManagedObjectID
  
  init(source: DynamicFeedPost) {
    self.id = source.rawID.value
    self.updatedAt = source.updatedAt.value
    self.imageURLString = source.imageURLString.value
    self.commentIDs = source.comments.value.map { $0.rawID.value }
    self.userID = source.user.value?.rawID.value
    self.managedObjectID = source.cs_id()
  }
}

extension DynamicFeedPost {
  
  static let imageURLs: [URL] = [
    "https://images.unsplash.com/photo-1482049016688-2d3e1b311543?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=953&q=80",
    "https://images.unsplash.com/photo-1546548970-71785318a17b?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=668&q=80",
    
    "https://images.unsplash.com/photo-1499028344343-cd173ffc68a9?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1650&q=80",
    
    "https://images.unsplash.com/photo-1541795795328-f073b763494e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=668&q=80",
    
    "https://images.unsplash.com/photo-1560192070-8439a735dfbc?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=582&q=80",
    
    "https://images.unsplash.com/photo-1457296898342-cdd24585d095?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1567&q=80",
    
    "https://images.unsplash.com/photo-1531326240216-7b04ad593229?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=936&q=80"
    ].map { URL(string: $0)! }
  
}

