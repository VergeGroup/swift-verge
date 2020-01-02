//
//  AnyEntity.swift
//  VergeORM
//
//  Created by muukii on 2020/01/02.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

struct AnyEntity : Hashable {
  
  final class AnyBox {
    
    var base: Any
    
    init(_ base: Any) {
      self.base = base
    }
  }
  
  static func == (lhs: AnyEntity, rhs: AnyEntity) -> Bool {
    lhs.identifier == rhs.identifier
  }
  
  func hash(into hasher: inout Hasher) {
    identifier.hash(into: &hasher)
  }
    
  var base: Any {
    get {
      box.base
    }
    set {
      if isKnownUniquelyReferenced(&box) {
        box.base = newValue
      } else {
        box = .init(newValue)
      }
    }
  }
  
  private var box: AnyBox
  private let identifier: AnyHashable
    
  init<Base: EntityType>(_ base: Base) {
    self.box = .init(base)
    self.identifier = base.id
  }
  
}
