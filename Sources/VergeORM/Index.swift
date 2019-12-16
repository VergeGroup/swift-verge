//
//  Index.swift
//  VergeORM
//
//  Created by muukii on 2019/12/17.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public protocol IndexesType {
  init()
}

extension IndexesType {
  
  static func memberMemoryOffset(_ keyPath: PartialKeyPath<Self>) -> Int {
    MemoryLayout<Self>.offset(of: keyPath)!
  }
}

fileprivate struct Wrapper<Schema: EntitySchemaType> {
  
  var base: Any
  private let _apply: (Any, BackingRemovingEntityStorage<Schema>) -> Any
  
  init<I: IndexType>(
    base: I,
    apply: @escaping (I, BackingRemovingEntityStorage<Schema>) -> I
  ) {
    
    self.base = base
    self._apply = { base, removing -> Any in
      apply(base as! I, removing)
    }
  }
  
  mutating func apply(removing: BackingRemovingEntityStorage<Schema>) {
    self.base = _apply(base, removing)
  }
}

@dynamicMemberLookup
public struct IndexesStorage<Schema: EntitySchemaType, Indexes: IndexesType> {
  
  private typealias Key = AnyKeyPath
  
  private let indexed = Indexes()
  
  private var backing: [Key : Wrapper<Schema>] = [:]
  
  init() {
    
  }
  
  private init(backing: [Key : Wrapper<Schema>]) {
    self.backing = backing
  }
  
}

extension IndexesStorage {
  
  mutating func apply(removing: BackingRemovingEntityStorage<Schema>) {
    backing.keys.forEach { key in
      backing[key]?.apply(removing: removing)
    }
  }
    
  public subscript <Index: IndexType>(dynamicMember keyPath: KeyPath<Indexes, IndexKey<Index>>) -> Index where Index.Schema == Schema {
    get {
      guard let raw = backing[keyPath] else {
        return Index()
      }
      return raw.base as! Index
    }
    mutating set {
      backing[keyPath] = newValue.wrapped()
    }
  }
}

public struct IndexKey<Index: IndexType> {
       
  public init() {}
}

public protocol IndexType {
  
  associatedtype Schema : EntitySchemaType
  
  init()
    
  mutating func apply(removing: BackingRemovingEntityStorage<Schema>)
}

extension IndexType {

  fileprivate func wrapped() -> Wrapper<Schema> {
    return .init(
      base: self,
      apply: { (base: Self, removing: BackingRemovingEntityStorage<Schema>) in
        var b = base
        b.apply(removing: removing)
        return b
    })
  }
  
}

public struct OrderedIDIndex<Schema: EntitySchemaType, Entity: EntityType>: IndexType, Equatable {
  
  private(set) var backing: [Entity.ID] = []
  
  public init() {
  }
  
  public mutating func apply(removing: BackingRemovingEntityStorage<Schema>) {
    guard let ids = removing._getTable(Entity.self) else {
      return
    }
    backing.removeAll { ids.contains($0) }
  }
    
}

extension OrderedIDIndex: RandomAccessCollection, MutableCollection, RangeReplaceableCollection {
  
  public mutating func append(_ newElement: __owned Entity.ID) {
    backing.append(newElement)
  }
      
  public subscript(position: Int) -> Entity.ID {
    get {
      backing[position]
    }
    set(newValue) {
      backing[position] = newValue
    }
  }
  
  public var startIndex: Int {
    backing.startIndex
  }
  
  public var endIndex: Int {
    backing.endIndex
  }
  
  public typealias Element = Entity.ID
  public typealias Index = Int
  public typealias SubSequence = ArraySlice<Entity.ID>
}
