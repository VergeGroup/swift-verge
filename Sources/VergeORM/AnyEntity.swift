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
  
  private final class Storage {
    
    var value: Any
    
    init(_ value: Any) {
      self.value = value
    }
    
  }
  
  private var storage: Storage
  
  var base: Any {
    _read { yield storage.value }
    _modify {
      let oldValue = storage.value
      if isKnownUniquelyReferenced(&storage) {
        yield &storage.value
      } else {
        storage = Storage(oldValue)
        yield &storage.value
      }
    }
  }
    
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
    self.storage = .init(base)
    self.identifier = base.entityID.any
  }
  
}
