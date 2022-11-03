//
//  AnyEntity.swift
//  VergeORM
//
//  Created by muukii on 2020/01/02.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

/// Type erased container
/// Identifier based Equality
struct AnyEntity : Hashable {
  
  var base: Any
    
  static func == (lhs: AnyEntity, rhs: AnyEntity) -> Bool {
    if lhs.identifier == rhs.identifier {
      return true
    }
    return false
  }
  
  func hash(into hasher: inout Hasher) {
    identifier.hash(into: &hasher)
  }
      
  private let identifier: AnyEntityIdentifier
        
  init<Base: EntityType>(_ base: Base) {
    self.base = base
    self.identifier = base.entityID.any
  }
  
}
