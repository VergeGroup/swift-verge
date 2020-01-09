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

#if !COCOAPODS
import VergeCore
#endif

@available(iOS 13, macOS 10.15, *)
extension EntityType {
  
  #if COCOAPODS
  public typealias Getter = Verge.Getter<Self>
  public typealias GetterSource<Source> = Verge.GetterSource<Source, Self>
  #else
  public typealias Getter = VergeCore.Getter<Self>
  public typealias GetterSource<Source> = VergeCore.GetterSource<Source, Self>
  #endif
  
}

public protocol DatabaseEmbedding {
  
  associatedtype Database: DatabaseType
  
  static var getterToDatabase: (Self) -> Database { get }
  
}

extension EqualityComputer where Input : DatabaseType {
  
  public static func tableEqual<E: EntityType>(_ entityType: E.Type) -> EqualityComputer<Input> {
    let checkTableUpdated = EqualityComputer<Input>.init(
      selector: { input -> Date in
        return input._backingStorage.entityBackingStorage.table(E.self).updatedAt
    },
      equals: { (old, new) -> Bool in
        old == new
    })
    return checkTableUpdated
  }
  
  public static func entityEqual<E: EntityType & Equatable>(_ entityID: E.EntityID) -> EqualityComputer<Input> {
    return .init(
      selector: { db in db.entities.table(E.self).find(by: entityID) },
      equals: { $0 == $1 }
    )
  }
  
}
