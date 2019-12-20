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

public struct EntityIdentifier<Entity: EntityType> : Hashable {
  
  public let raw: Entity.IdentifierType
  
  public init(_ raw: Entity.IdentifierType) {
    self.raw = raw
  }
}

/// A protocol describes object is an Entity.
///
/// EntityType has VergeTypedIdentifiable.
/// You might use IdentifiableEntityType instead, if you create SwiftUI app.
public protocol EntityType {
  
  associatedtype IdentifierType: Hashable
   
  var id: Identifier { get }
  
  #if COCOAPODS
  typealias EntityTable = Verge.EntityTable<Self>
  typealias EntityTableKey = Verge.EntityTableKey<Self>
  #else
  typealias EntityTable = VergeORM.EntityTable<Self>
  typealias EntityTableKey = VergeORM.EntityTableKey<Self>
  #endif
}

extension EntityType {
  
  public typealias Identifier = EntityIdentifier<Self>
  
  public typealias ID = Identifier
  
}

struct EntityName: Hashable {
  let name: String
}

extension EntityType {
     
  static var entityName: EntityName {
    .init(name: String(reflecting: self))
  }
  
}

