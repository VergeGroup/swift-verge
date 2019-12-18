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

public enum BatchUpdateError: Error {
  case aborted
}

public final class DatabaseBatchUpdateContext<Database: DatabaseType> {
  
  public let current: Database
  
  public var insertsOrUpdates: EntityTablesStorage<Database.Schema> = .init()
  public var deletes: BackingRemovingEntityStorage<Database.Schema> = .init()
  public var indexes: IndexesStorage<Database.Schema, Database.Indexes>
    
  init(current: Database) {
    self.current = current
    self.indexes = current._backingStorage.indexesStorage
  }
  
  public func abort() throws -> Never {
    throw BatchUpdateError.aborted
  }
}

extension DatabaseType {
    
  /// Performs operations to update entities and indexes
  /// If can be run on background thread with locking.
  ///
  /// - Parameter update:
  public mutating func performBatchUpdates<Result>(_ update: (DatabaseBatchUpdateContext<Self>) throws -> Result) rethrows -> Result {
            
    let context = DatabaseBatchUpdateContext<Self>(current: self)
    do {
      let result = try update(context)
      
      middlewares.forEach {
        $0.performAfterUpdates(context: context)
      }
      
      do {
        var target = self._backingStorage.entityBackingStorage
        target._merge(otherStorage: context.insertsOrUpdates)
        target._subtract(otherStorage: context.deletes)
        self._backingStorage.entityBackingStorage = target
      }
                 
      do {
        context.indexes.apply(removing: context.deletes)
        self._backingStorage.indexesStorage = context.indexes
      }
            
      return result
    } catch {
      throw error
    }
  }
}
