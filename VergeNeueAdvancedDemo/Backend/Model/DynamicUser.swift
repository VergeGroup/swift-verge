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
  let name = Value.Optional<String>("name")
  let posts = Relationship.ToManyUnordered<DynamicFeedPost>("posts")
}
