//
// Copyright (c) 2020 muukii
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

@available(*, deprecated, renamed: "InstancePool")
public typealias CachedMapStorage<Source, Target> = InstancePool<Source, Target>

/// A storage object that retains projected instance from source by identified key.
public final class InstancePool<Source, Target>: @unchecked Sendable {

  struct Artifact {
    let source: Source
    var value: Target
  }

  private let generateKey: @Sendable (Source) -> AnyHashable
  private let updateCondition: @Sendable (Source, Source) -> Bool

  private var innerStorage: [AnyHashable: Artifact] = [:]

  private let outerLock = NSLock()

  /// Creates an instance
  ///
  /// - Parameters:
  ///   - keySelector: A closure that gives key to identify the mapped instance.
  ///   - shouldUpdate: A closure that indicates whether cached one replace with new mapped instance.
  public init<Key: Hashable>(
    keySelector: @escaping @Sendable (Source) -> Key,
    shouldUpdate: @escaping @Sendable (_ cached: Source, _ new: Source) -> Bool = { _, _ in false }
  ) {
    self.updateCondition = shouldUpdate
    self.generateKey = {
      AnyHashable(keySelector($0))
    }
  }

  public func purgeCache() {
    outerLock.lock()
    defer {
      outerLock.unlock()
    }
    innerStorage = [:]
  }

  public func map<C: Collection>(
    from collection: C,
    sweepsUnused: Bool,
    makeNew: (C.Element) throws -> Target,
    update: (C.Element, inout Target) -> Void
  ) rethrows -> [Target] where C.Element == Source {

    outerLock.lock()
    defer {
      outerLock.unlock()
    }

    let keys = collection.map(generateKey)

    let result = try zip(collection, keys).map { (element, key) -> Target in
      if let cached = innerStorage[key], !updateCondition(cached.source, element) {
        update(element, &innerStorage[key]!.value)
        return innerStorage[key]!.value
      }
      let newObject = try makeNew(element)
      innerStorage[key] = Artifact(source: element, value: newObject)
      return newObject
    }

    if sweepsUnused {
      let unusedKeys = Set(innerStorage.keys).subtracting(keys)
      
      for key in unusedKeys {
        innerStorage.removeValue(forKey: key)
      }
    }

    return result
  }

  public func compactMap<C: Collection>(
    from collection: C,
    sweepsUnused: Bool,
    makeNew: (C.Element) throws -> Target?,
    update: (C.Element, inout Target) -> Void
  )
    rethrows -> [Target] where C.Element == Source
  {

    outerLock.lock()
    defer {
      outerLock.unlock()
    }

    let keys = collection.map(generateKey)

    let result = try zip(collection, keys).compactMap { (element, key) -> Target? in
      if let cached = innerStorage[key], !updateCondition(cached.source, element) {
        update(element, &innerStorage[key]!.value)
        return innerStorage[key]!.value
      }
      guard let newObject = try makeNew(element) else { return nil }
      innerStorage[key] = Artifact(source: element, value: newObject)
      return newObject
    }

    if sweepsUnused {
      let unusedKeys = Set(innerStorage.keys).subtracting(keys)
      
      for key in unusedKeys {
        innerStorage.removeValue(forKey: key)
      }
    }

    return result
  }
}

extension Collection {

  /**
   Returns an array containing the results of mapping the given closure over the sequence’s elements.
   Especially, it uses a cached instance to return.
   You can set your expectation on how it caches from creating `CachedMapStorage`.

   It helps to create a store object or view model from immutable data.

   - Author: Verge
   */
  public func cachedMap<U>(
    using pool: InstancePool<Self.Element, U>,
    sweepsUnused: Bool = false,
    makeNew: (Self.Element) throws -> U,
    update: (Self.Element, inout U) -> Void = { _, _ in }
  ) rethrows -> [U] {
    return try pool.map(from: self, sweepsUnused: sweepsUnused, makeNew: makeNew, update: update)
  }

  /**
   Returns an array containing the results of mapping the given closure over the sequence’s elements.
   Especially, it uses a cached instance to return.
   You can set your expectation on how it caches from creating `CachedMapStorage`.

   It helps to create a store object or view model from immutable data.

   - Author: Verge
   */
  public func cachedCompactMap<U>(
    using pool: InstancePool<Self.Element, U>,
    sweepsUnused: Bool = false,
    makeNew: (Self.Element) throws -> U?,
    update: (Self.Element, inout U) -> Void = { _, _ in }
  ) rethrows -> [U] {
    return try pool.compactMap(from: self, sweepsUnused: sweepsUnused, makeNew: makeNew, update: update)
  }

}
