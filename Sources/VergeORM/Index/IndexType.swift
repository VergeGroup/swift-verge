//
// Copyright (c) 2019 muukii
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

/// A wrapper container to erase type of Index
fileprivate struct IndexWrapper<Schema: EntitySchemaType> {
  
  var base: Any
  private let _apply: (Any, _ removing: Set<AnyHashable>, _ entityName: EntityTableIdentifier) -> Any
  
  init<I: IndexType>(
    base: I,
    apply: @escaping (I, _ removing: Set<AnyHashable>, _ entityName: EntityTableIdentifier) -> I
  ) {
    
    self.base = base
    self._apply = { base, removing, entityName -> Any in
      apply(base as! I, removing, entityName)
    }
  }
  
  mutating func apply(removing: Set<AnyHashable>, entityName: EntityTableIdentifier) {
    self.base = _apply(base, removing, entityName)
  }
}

@dynamicMemberLookup
public struct IndexesStorage<Schema: EntitySchemaType, Indexes: IndexesType> {

  private typealias Key = AnyKeyPath

  private var backing: [Key : IndexWrapper<Schema>] = [:]
  
  init() {
    
  }
  
  private init(backing: [Key : IndexWrapper<Schema>]) {
    self.backing = backing
  }
  
}

extension IndexesStorage {
  
  mutating func apply(edits: [EntityTableIdentifier : EntityModifierType]) {
    edits.forEach { _, value in
      apply(
        removing: value._deletes,
        entityName: value.entityName
      )
    }
  }
  
  @inline(__always)
  private mutating func apply(removing: Set<AnyHashable>, entityName: EntityTableIdentifier) {
    backing.keys.forEach { key in
      backing[key]?.apply(removing: removing, entityName: entityName)
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

/// A protocol IndexContainer must be implemented
public protocol IndexType {
  
  typealias Key = IndexKey<Self>
  
  associatedtype Schema : EntitySchemaType
  
  /// To ORM create Index container
  init()
      
  /// Internal method
  /// - Parameters:
  ///   - removing: a set of entity id that will be removed from store
  ///   - entityName: the entity name of removing
  ///
  /// You can do this `removing.first as? YourEntity.EntityID`
  mutating func _apply(removing: Set<AnyHashable>, entityName: EntityTableIdentifier)
}

extension IndexType {

  fileprivate func wrapped() -> IndexWrapper<Schema> {
    return .init(
      base: self,
      apply: { (base: Self, removing: Set<AnyHashable>, entityName: EntityTableIdentifier) in
        var b = base
        b._apply(removing: removing, entityName: entityName)
        return b
    })
  }
  
}
