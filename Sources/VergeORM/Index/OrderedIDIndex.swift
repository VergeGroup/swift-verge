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

/// Ordered Collection based index storage
public struct OrderedIDIndex<Schema: EntitySchemaType, Entity: EntityType>: IndexType, Equatable {
  
  // FIXME: To be faster filter, use BTree
  private var backing: [Entity.ID] = []
  
  public init() {
  }
  
  public mutating func _apply(removing: BackingRemovingEntityStorage<Schema>) {
    guard let ids = removing._getTable(Entity.self) else {
      return
    }
    backing.removeAll { ids.contains($0) }
  }
  
}

extension OrderedIDIndex: RandomAccessCollection, MutableCollection, RangeReplaceableCollection {
  
  public typealias Element = Entity.ID
  public typealias Index = Int
  public typealias SubSequence = ArraySlice<Entity.ID>
  
  public mutating func append(_ newElement: __owned Entity.ID) {
    backing.append(newElement)
  }
  
  public subscript(position: Int) -> Entity.ID {
    _read {
      yield backing[position]
    }
    _modify {
      yield &backing[position]
    }
  }
  
  public var startIndex: Int {
    backing.startIndex
  }
  
  public var endIndex: Int {
    backing.endIndex
  }
  
}
