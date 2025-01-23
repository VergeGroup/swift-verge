//
// Copyright (c) 2021 Hiroshi Kimura(Muukii) <muukii.app@gmail.com>
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

public struct DynamicProperty<T> {

  public var value: T? {
    get {

      storage.lock.lock()

      // Do not directly cast using `as?`.
      guard let value = storage.synchronized_value(for: key) else {
        storage.lock.unlock()
        return nil
      }

      storage.lock.unlock()

      return value as? T
    }
    nonmutating set {
      storage.lock.lock()
      storage.synchronized_setValue(newValue as Any, for: key)
      storage.lock.unlock()
    }
  }

  public let key: String
  private let storage: DynamicPropertyStorage.Storage<Any>

  init(key: String, storage: DynamicPropertyStorage.Storage<Any>) {
    self.key = key
    self.storage = storage
  }

  private func _doIfChanged(
    value: T,
    compare: (T, T) -> Bool,
    perform: (T) -> Void
  ) {

    storage.lock.lock()

    // Do not directly cast using `as?`.
    // To detect storage does not have value for key when T is optinal type.
    guard let cachedRawValue = storage.synchronized_value(for: key) else {
      storage.synchronized_setValue(value, for: key)
      storage.lock.unlock()
      perform(value)
      return
    }

    let cachedValue = cachedRawValue as! T

    guard compare(cachedValue, value) == false else {
      storage.lock.unlock()
      return
    }

    storage.synchronized_setValue(value, for: key)

    storage.lock.unlock()

    perform(value)

  }

  /// [Experimental]
  /// should be renamed
  public func doIfChanged(
    _ value: T,
    _ compare: (T, T) -> Bool,
    _ perform: (T) -> Void
  ) {

    _doIfChanged(
      value: value,
      compare: compare,
      perform: perform
    )

  }

  /// [Experimental]
  /// should be renamed
  public func doIfChanged(
    _ value: T,
    _ perform: (T) -> Void
  ) where T : Equatable {

    _doIfChanged(
      value: value,
      compare: ==,
      perform: perform
    )

  }

}

public final class DynamicPropertyStorage {

  final class Storage<T> {

    let lock = NSLock()

    var rawStorage: [String : T] = [:]

    func synchronized_value(for key: String) -> T? {

      guard let value = rawStorage[key] else {
        return nil
      }

      return value
    }

    func synchronized_setValue(_ value: T, for key: String) {
      rawStorage[key] = value
    }

    func synchronized_removeValue(for key: String) {
      rawStorage.removeValue(forKey: key)
    }
  }

  struct CodeLocation: Hashable {
    let file: String
    let line: UInt
    let column: UInt

    func makeKey() -> String {
      "\(file).\(line).\(column)"
    }
  }

  private let _anyStorage: Storage<Any> = .init()

  public init() {
    
  }

  public func defineProperty<T>(
    file: StaticString = #file,
    line: UInt = #line,
    column: UInt = #column,
    _ type: T.Type
  ) -> DynamicProperty<T> {

    let codeLocation = CodeLocation(file: file.description, line: line, column: column)

    return .init(key: codeLocation.makeKey(), storage: _anyStorage)

  }

  /// [Experimental]
  /// should be renamed
  public func doIfChanged<T>(
    file: StaticString = #file,
    line: UInt = #line,
    column: UInt = #column,
    _ value: T,
    _ compare: (T, T) -> Bool,
    _ perform: (T) -> Void
  ) {

    let property = defineProperty(file: file, line: line, column: column, T.self)

    property.doIfChanged(
      value,
      compare,
      perform
    )

  }

  /// [Experimental]
  /// should be renamed
  public func doIfChanged<T>(
    file: StaticString = #file,
    line: UInt = #line,
    column: UInt = #column,
    _ value: T,
    _ perform: (T) -> Void
  ) where T : Equatable {

    let property = defineProperty(file: file, line: line, column: column, T.self)

    property.doIfChanged(
      value,
      perform
    )

  }

}

nonisolated(unsafe) private var _storageKey: Void?

extension NSObject {

  public var associatedProperties: DynamicPropertyStorage {

    objc_sync_enter(self)
    defer {
      objc_sync_exit(self)
    }

    if let associated = objc_getAssociatedObject(self, &_storageKey)
        as? DynamicPropertyStorage
    {
      return associated
    } else {
      let associated = DynamicPropertyStorage()
      objc_setAssociatedObject(self, &_storageKey, associated, .OBJC_ASSOCIATION_RETAIN)
      return associated
    }

  }

}


