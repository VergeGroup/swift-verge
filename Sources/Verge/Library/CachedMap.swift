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

public struct ConcurrentMapResult<T> {

  public var elements: [T]

  public var errors: [Swift.Error]

  public var hasError: Bool {
    !errors.isEmpty
  }

  public init(elements: [T], errors: [Error]) {
    self.elements = elements
    self.errors = errors
  }

}

/**
 A storage object that retains projected instance from source by identified key.
 */
public final class CachedMapStorage<Source, Target> {

  struct Artifact {
    let source: Source
    var value: Target
  }

  private let generateKey: (Source) -> AnyHashable
  private let updateCondition: (Source, Source) -> Bool

  private var innerStorage: [AnyHashable : Artifact] = [:]

  private let outerLock = NSLock()

  /// Creates an instance
  ///
  /// - Parameters:
  ///   - keySelector: A closure that gives key to identify the mapped instance.
  ///   - shouldUpdate: A closure that indicates whether cached one replace with new mapped instance.
  public init<Key : Hashable>(
    keySelector: @escaping (Source) -> Key,
    shouldUpdate: @escaping (_ cached: Source, _ new: Source) -> Bool = { _, _ in false }
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
    makeNew: (C.Element) throws -> Target,
    update: (C.Element, inout Target) -> Void
  ) rethrows -> [Target] where C.Element == Source {

    outerLock.lock()
    defer {
      outerLock.unlock()
    }

    return
      try collection.map { (element) -> Target in
        let key = generateKey(element)
        if let cached = innerStorage[key], !updateCondition(cached.source, element) {
          update(element, &innerStorage[key]!.value)
          return innerStorage[key]!.value
        }
        let newObject = try makeNew(element)
        innerStorage[key] = Artifact(source: element, value: newObject)
        return newObject
    }
  }

  public func concurrentMap<C: Collection>(from collection: C, makeNew: (C.Element) throws -> Target) -> ConcurrentMapResult<Target> where C.Element == Source {

    outerLock.lock()
    defer {
      outerLock.unlock()
    }

    let currentCache = innerStorage
    let source = Array(collection)

    /// A buffer to retain a created value for locking-free
    /// It takes few of memory.
    var newObjectResults = Array<(AnyHashable, Artifact)?>.init(repeating: nil, count: source.count)

    /// Concurrent perform without locking
    let result = newObjectResults.withUnsafeMutableBufferPointer { (buffer) in
      Array(collection)._concurrentMap { (element, i) throws -> Target in
        let key = generateKey(element)

        if let cached = currentCache[key], !updateCondition(cached.source, element) {
          return cached.value
        }

        let newObject = try makeNew(element)
        let artifact = Artifact(source: element, value: newObject)

        let targetPointer = buffer.baseAddress!.advanced(by: i)
        targetPointer.pointee = (key, artifact)

        return newObject
      }
    }

    /// Aggregate new created object into cache storage.

    newObjectResults
      .forEach { element in
        guard let element = element else { return }
        innerStorage[element.0] = element.1
    }

    return result
  }

  public func compactMap<C: Collection>(from collection: C, makeNew: (C.Element) throws -> Target?) rethrows -> [Target] where C.Element == Source {

    outerLock.lock()
    defer {
      outerLock.unlock()
    }

    return
      try collection.compactMap { (element) -> Target? in
        let key = generateKey(element)
        if let cached = innerStorage[key], !updateCondition(cached.source, element) {
          return cached.value
        }
        guard let newObject = try makeNew(element) else { return nil }
        innerStorage[key] = Artifact(source: element, value: newObject)
        return newObject
    }
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
    using storage: CachedMapStorage<Self.Element, U>,
    makeNew: (Self.Element) throws -> U,
    update: (Self.Element, inout U) -> Void = { _, _ in }
  ) rethrows -> [U] {
    return try storage.map(from: self, makeNew: makeNew, update: update)
  }

  /**
   Returns an array containing the results of mapping the given closure over the sequence’s elements.
   Especially, it uses a cached instance to return.
   You can set your expectation on how it caches from creating `CachedMapStorage`.

   It helps to create a store object or view model from immutable data.

   - Author: Verge
   */
  public func cachedCompactMap<U>(using storage: CachedMapStorage<Self.Element, U>, makeNew: (Self.Element) throws -> U?) rethrows -> [U] {
    return try storage.compactMap(from: self, makeNew: makeNew)
  }

  /**
   Returns an array containing the results of mapping the given closure over the sequence’s elements.
   Especially, it uses a cached instance to return.
   You can set your expectation on how it caches from creating `CachedMapStorage`.

   It helps to create a store object or view model from immutable data.

   - Author: Verge
   */
  public func cachedConcurrentMap<U>(using storage: CachedMapStorage<Self.Element, U>, makeNew: (Self.Element) throws -> U) -> ConcurrentMapResult<U> {
    return storage.concurrentMap(from: self, makeNew: makeNew)
  }

}

extension Array {

  fileprivate func _concurrentMap<U>(_ transform: (Element, Int) throws -> U) -> ConcurrentMapResult<U> {

    var resultBuffer = [U?].init(repeating: nil, count: count)
    var errorsBuffer = [Error?].init(repeating: nil, count: count)

    errorsBuffer.withUnsafeMutableBufferPointer { errorsBuffer in

      resultBuffer.withUnsafeMutableBufferPointer { (targetBuffer) -> Void in

        self.withUnsafeBufferPointer { (sourceBuffer) -> Void in

          DispatchQueue.concurrentPerform(iterations: count) { i in
            let sourcePointer = sourceBuffer.baseAddress!.advanced(by: i)
            do {
              let r = try transform(sourcePointer.pointee, i)
              let targetPointer = targetBuffer.baseAddress!.advanced(by: i)
              targetPointer.pointee = r
            } catch {
              errorsBuffer.baseAddress?.advanced(by: i).pointee = error
            }

          }

        }
      }
    }

    return .init(elements: resultBuffer.compactMap { $0 }, errors: errorsBuffer.compactMap { $0 })
  }

}
