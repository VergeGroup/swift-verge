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
import VergeStore
#endif

extension EntityType {
  
  #if COCOAPODS
  public typealias Derived = Verge.Derived<Self>
  #else
  public typealias Derived = VergeStore.Derived<Self>
  #endif
  
}

extension MemoizeMap where Input : ChangesType, Input.Value : DatabaseEmbedding {
  
  fileprivate static func makeEntityQuery<Entity: EntityType>(entityID: Entity.EntityID) -> MemoizeMap<Input, Entity?> {
    
    let path = Input.Value.getterToDatabase
      
    return .init(makeInitial: { changes in
      
      path(changes.current).entities.table(Entity.self).find(by: entityID)
      
    }, update: { changes in
      
      let hasChanges = changes.asChanges().hasChanges(
        compose: { (composing) -> Input.Value.Database in
          let db = type(of: composing.root).getterToDatabase(composing.root)
          return db
      }, comparer: { old, new in
        Comparer<Input.Value.Database>.init(or: [
          .databaseNoUpdates(),
          .tableNoUpdates(Entity.self),
          .changesNoContains(entityID)
        ])
          .equals(old, new)
      })
      
      guard !hasChanges else {
        return .noChanages
      }
      
      let entity = path(changes.current).entities.table(Entity.self).find(by: entityID)
      return .updated(entity)
    })
  }
  
}

extension StoreType where State : DatabaseEmbedding {
    
  public func derived<Entity: EntityType>(_ entityID: Entity.EntityID, entityEquals: @escaping (Entity?, Entity?) -> Bool) -> Derived<Entity?> {
        
    let d = derived(
      .makeEntityQuery(entityID: entityID),
      dropsOutput: { changes in
        changes.noChanges(\.root, entityEquals)
    })
        
    return d
  }
  
}
