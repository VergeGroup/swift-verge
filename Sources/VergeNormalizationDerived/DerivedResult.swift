//
//  File.swift
//  
//
//  Created by Muukii on 2023/09/11.
//

import Foundation
import Verge

/// A result instance that contains created Derived object
/// While creating non-null derived from entity id, some entity may be not founded.
/// Created derived object are stored in hashed storage to the consumer can check if the entity was not found by the id.
public struct DerivedResult<Entity: EntityType, Derived: DerivedType> {

  /// A dictionary of Derived that stored by id
  /// It's faster than filtering values array to use this dictionary to find missing id or created id.
  public private(set) var storage: [Entity.TypedID : Derived] = [:]

  /// An array of Derived that orderd by specified the order of id.
  public private(set) var values: [Derived]

  public init() {
    self.storage = [:]
    self.values = []
  }

  public mutating func append(derived: Derived, id: Entity.TypedID) {
    storage[id] = derived
    values.append(derived)
  }

}

public typealias NonNullDerivedResult<Entity: EntityType> = DerivedResult<Entity, Entity.NonNullDerived>
