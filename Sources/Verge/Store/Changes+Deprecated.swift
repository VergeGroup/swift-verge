//
//  Changes+Deprecated.swift
//  Verge
//
//  Created by Muukii on 2020/12/22.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

// MARK: - Deprecates

extension Changes {

  @available(*, deprecated, message: "Create Comparer instead using closure")
  @inline(__always)
  public func ifChanged<Composed, Result>(
    _ compose: (Changes) -> Composed,
    _ compare: @escaping (Composed, Composed) -> Bool,
    _ perform: (Composed) throws -> Result
  ) rethrows -> Result? {
    guard let result = takeIfChanged(compose, compare) else {
      return nil
    }

    return try perform(result)
  }

  /// Takes a composed value if it's changed from old value.
  @available(*, deprecated, message: "Create Comparer instead using closure")
  @inline(__always)
  public func takeIfChanged<T>(
    _ keyPath: ChangesKeyPath<T>,
    _ compare: @escaping (T, T) -> Bool
  ) -> T? {
    takeIfChanged({ $0[keyPath: keyPath] }, .init(compare))
  }

  @available(*, deprecated, message: "Create Comparer instead using closure")
  @inline(__always)
  public func hasChanges<Composed>(
    _ compose: (Changes) -> Composed,
    _ compare: @escaping (Composed, Composed) -> Bool
  ) -> Bool {
    hasChanges(compose, .init(compare))
  }

  /// Returns boolean that indicates value specified by keyPath contains changes with compared old and new.
  @available(*, deprecated, message: "Create Comparer instead using closure")
  @inline(__always)
  public func hasChanges<T>(
    _ keyPath: ChangesKeyPath<T>,
    _ compare: @escaping (T, T) -> Bool
  ) -> Bool {
    hasChanges({ $0[keyPath: keyPath] }, compare)
  }

  /// Returns boolean that indicates value specified by keyPath contains **NO** changes with compared old and new.
  @available(*, deprecated, message: "Create Comparer instead using closure")
  @inline(__always)
  public func noChanges<T>(_ keyPath: ChangesKeyPath<T>, _ compare: @escaping (T, T) -> Bool) -> Bool {
    !hasChanges(keyPath, .init(compare))
  }

  /// Takes a composed value if it's changed from old value.
  @available(*, deprecated, message: "Create Comparer instead using closure")
  @inline(__always)
  public func takeIfChanged<Composed>(
    _ compose: (Changes) throws -> Composed,
    _ compare: @escaping (Composed, Composed) -> Bool
  ) rethrows -> Composed? {

    try takeIfChanged(compose, .init(compare))
  }

  /// Do a closure if value specified by keyPath contains changes.
  @available(*, deprecated, message: "Create Comparer instead using closure")
  public func ifChanged<T, Result>(
    _ selector: ChangesKeyPath<T>,
    _ compare: @escaping (T, T) -> Bool,
    _ perform: (T) throws -> Result
  ) rethrows -> Result? {
    try ifChanged(selector, .init(compare), perform)
  }

  @inline(__always)
  @available(*, deprecated, renamed: "ifChanged(_:_:_:)")
  public func ifChanged<Composed, Result>(
    compose: (Changes) -> Composed,
    comparer: @escaping (Composed, Composed) -> Bool,
    perform: (Composed) throws -> Result
  ) rethrows -> Result? {
    try ifChanged(compose, comparer, perform)
  }

  @available(*, deprecated, renamed: "ifChanged(_:_:)")
  public func ifChanged<Composed: Equatable, Result>(
    compose: (Changes) -> Composed,
    perform: (Composed) throws -> Result
  ) rethrows -> Result? {
    try ifChanged(compose, perform)
  }
}
