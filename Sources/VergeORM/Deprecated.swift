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

extension StoreType where State : DatabaseEmbedding {

  /// Returns a derived object that provides a concrete entity according to the updating source state
  /// It uses the last value if the entity has been removed source.
  /// You can get a flag that indicates whether the entity is live or removed which from `NonNullEntityWrapper<T>`
  ///
  /// If you call this method in many time, it's not so big issue.
  /// Because, the backing derived-object to construct itself would be cached.
  /// A pointer of the result derived object will be different from each other, but the backing source will be shared.
  ///
  @available(*, deprecated, message: "Use Derived.combined() instead")
  @inline(__always)
  public func derivedNonNull<E0: EntityType & Equatable, E1: EntityType & Equatable>(
    from e0ID: E0.EntityID,
    _ e1ID: E1.EntityID,
    queue: TargetQueue = .passthrough
  ) throws -> Derived<(NonNullEntityWrapper<E0>, NonNullEntityWrapper<E1>)> {

    Derived.combined(
      try derivedNonNull(from: e0ID, queue: queue),
      try derivedNonNull(from: e1ID, queue: queue),
      queue: queue
    )
  }

  /// Returns a derived object that provides a concrete entity according to the updating source state
  /// It uses the last value if the entity has been removed source.
  /// You can get a flag that indicates whether the entity is live or removed which from `NonNullEntityWrapper<T>`
  ///
  /// If you call this method in many time, it's not so big issue.
  /// Because, the backing derived-object to construct itself would be cached.
  /// A pointer of the result derived object will be different from each other, but the backing source will be shared.
  ///
  @available(*, deprecated, message: "Use Derived.combined() instead")
  @inline(__always)
  public func derivedNonNull<E0: EntityType & Equatable, E1: EntityType & Equatable, E2: EntityType & Equatable>(
    from e0ID: E0.EntityID,
    _ e1ID: E1.EntityID,
    _ e2ID: E2.EntityID,
    queue: TargetQueue = .passthrough
  ) throws -> Derived<(NonNullEntityWrapper<E0>, NonNullEntityWrapper<E1>, NonNullEntityWrapper<E2>)> {

    Derived.combined(
      try derivedNonNull(from: e0ID, queue: queue),
      try derivedNonNull(from: e1ID, queue: queue),
      try derivedNonNull(from: e2ID, queue: queue),
      queue: queue
    )
  }
}
