//
//  BackingOrderTableStorage.swift
//  VergeORM
//
//  Created by muukii on 2019/12/13.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public struct OrderTablePropertyKey<S: EntityType> {
  
  public var typeName: String {
    String(reflecting: S.self)
  }
  
  public let name: String
  
  public init(name: String) {
    self.name = name
  }
}

public struct OrderTable<Entity: EntityType, Trait: AccessControlType>: RandomAccessCollection {
  
  public subscript(position: Int) -> Entity.ID {
    backing[position] as! Entity.ID
  }
  
  public var startIndex: Int {
    backing.startIndex
  }
  
  public var endIndex: Int {
    backing.endIndex
  }
  
  public typealias Element = Entity.ID
  public typealias Index = Int
  
  private(set) var backing: [AnyHashable] = []
  
  init(backing: [AnyHashable]) {
    self.backing = backing
  }
  
}

extension OrderTable: MutableCollection where Trait == Write {
  
  public subscript(position: Int) -> Entity.ID {
    get {
      backing[position] as! Entity.ID
    }
    set(newValue) {
      backing[position] = newValue
    }
  }
  
  @discardableResult
  public mutating func append(_ entity: Entity) -> Entity.ID {
    append(entity.id)
  }
  
  @discardableResult
  public mutating func append(_ entityID: Entity.ID) -> Entity.ID {
    backing.append(entityID)
    return entityID
  }
  
  @discardableResult
  public mutating func append<S: Sequence>(contentsOf addingEntities: S) -> [Entity.ID] where S.Element == Entity {
    append(contentsOf: addingEntities.map { $0.id })
  }
  
  @discardableResult
  public mutating func append<S: Sequence>(contentsOf addingEntities: S) -> [Entity.ID] where S.Element == Entity.ID {
    let ids: [Entity.ID] = addingEntities.map { $0 }
    backing.append(contentsOf: ids)
    return ids
  }
  
}

public protocol OrderTablesType {
  init()
}

@dynamicMemberLookup
public struct BackingOrderTableStorage<OrderTables: OrderTablesType, Trait: AccessControlType> {
  
  var orderTableStorage: [String : [AnyHashable]]
  
  private let index = OrderTables()
  
  public init() {
    self.orderTableStorage = [:]
  }
  
  private init(orderTableStorage: [String : [AnyHashable]]) {
    self.orderTableStorage = orderTableStorage
  }
     
  public subscript <U: EntityType>(dynamicMember keyPath: KeyPath<OrderTables, OrderTablePropertyKey<U>>) -> OrderTable<U, Trait> {
    get {
      let key = index[keyPath: keyPath]
      guard let rawTable = orderTableStorage[key.typeName] else {
        return OrderTable(backing: [])
      }
      return OrderTable(backing: rawTable)
    }
  }
  
}

extension BackingOrderTableStorage where Trait == Read {
  func makeWriable() -> BackingOrderTableStorage<OrderTables, Write> {
    .init(orderTableStorage: orderTableStorage)
  }
}

extension BackingOrderTableStorage where Trait == Write {
  
  public subscript <U: EntityType>(dynamicMember keyPath: KeyPath<OrderTables, OrderTablePropertyKey<U>>) -> OrderTable<U, Trait> {
    mutating get {
      let key = index[keyPath: keyPath]
      guard let rawTable = orderTableStorage[key.typeName] else {
        orderTableStorage[key.typeName] = []
        return orderTableStorage[key.typeName].map {
          OrderTable(backing: $0)
          }!
      }
      return OrderTable(backing: rawTable)
    }
    set {
      let key = index[keyPath: keyPath]
      orderTableStorage[key.typeName] = newValue.backing
    }
  }
  
  func makeReadonly() -> BackingOrderTableStorage<OrderTables, Read> {
    .init(orderTableStorage: orderTableStorage)
  }
   
}
