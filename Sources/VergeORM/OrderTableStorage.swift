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

public struct OrderTableKey<S: EntityType> {
  
  public var typeName: String {
    String(reflecting: S.self)
  }
  
  public let name: String
  
  public init(name: String) {
    self.name = name
  }
}

public struct OrderTable<Entity: EntityType, Trait: AccessControlType>: Equatable, RandomAccessCollection {
  
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

extension OrderTable: RangeReplaceableCollection, MutableCollection where Trait == Write {
  public init() {
    
  }
    
  public subscript(position: Int) -> Entity.ID {
    get {
      backing[position] as! Entity.ID
    }
    set(newValue) {
      backing[position] = newValue
    }
  }
  
  public mutating func append(_ newElement: __owned Entity.ID) {
    backing.append(newElement)
  }
  
  public mutating func append<S>(contentsOf newElements: __owned S) where S : Sequence, OrderTable.Element == S.Element {
    backing.append(contentsOf: newElements.map { $0 })
  }
  
}

public protocol OrderTablesType {
  init()
}

@dynamicMemberLookup
public struct OrderTableStorage<OrderTables: OrderTablesType, Trait: AccessControlType> {
  
  var orderTableStorage: [String : [AnyHashable]]
  
  private let index = OrderTables()
  
  public init() {
    self.orderTableStorage = [:]
  }
  
  private init(orderTableStorage: [String : [AnyHashable]]) {
    self.orderTableStorage = orderTableStorage
  }
     
  public subscript <U: EntityType>(dynamicMember keyPath: KeyPath<OrderTables, OrderTableKey<U>>) -> OrderTable<U, Trait> {
    get {
      let key = index[keyPath: keyPath]
      guard let rawTable = orderTableStorage[key.typeName] else {
        return OrderTable(backing: [])
      }
      return OrderTable(backing: rawTable)
    }
  }
  
}

extension OrderTableStorage where Trait == Read {
  func makeWriable() -> OrderTableStorage<OrderTables, Write> {
    .init(orderTableStorage: orderTableStorage)
  }
}

extension OrderTableStorage where Trait == Write {
  
  public subscript <U: EntityType>(dynamicMember keyPath: KeyPath<OrderTables, OrderTableKey<U>>) -> OrderTable<U, Trait> {
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
  
  func makeReadonly() -> OrderTableStorage<OrderTables, Read> {
    .init(orderTableStorage: orderTableStorage)
  }
   
}
