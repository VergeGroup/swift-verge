//
// Copyright (c) 2020 Hiroshi Kimura(Muukii) <muuki.app@gmail.com>
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

#if canImport(SwiftUI) && canImport(Combine)

import SwiftUI
import Combine

/**
 A view that injects a state from `Store` or `Derived`.
 `content: @escaping (StateProvider) -> Content` will continue updates each `Store` or `Derived` updating
 - TODO:
   - Setting memoization and dropping duplicated output value
 */
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct UseState<Value, Content: View>: View {

  @ObservedObject private var observableObject: _VergeObservableObjectBase

  private let content: (Changes<Value>) -> Content
  private let updateValue: () -> Changes<Value>

  fileprivate init(
    updateTrigger: _VergeObservableObjectBase,
    updateValue: @escaping () -> Changes<Value>,
    content: @escaping (Changes<Value>) -> Content
  ) {
    self.observableObject = updateTrigger
    self.content = content
    self.updateValue = updateValue
  }

  public var body: some View {
    let changes = updateValue()
    return content(changes)
  }

}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension UseState {

  /// Initialize from `Store`
  ///
  /// - Complexity: Depends on the map parameter
  /// - Parameters:
  ///   - store:
  ///   - content:
  public init<Store: StoreType>(
    _ store: Store,
    _ map: MemoizeMap<Changes<Store.State>, Value>,
    @ViewBuilder content: @escaping (Changes<Value>) -> Content
  ) {

    var current: Changes<Value>?

    let store = store.asStore()

    self.init(
      updateTrigger: store,
      updateValue: {
        if let _current = current {
          switch map.makeResult(store.state) {
          case .noChanages:
            return _current
          case .updated(let value):
            let next = _current.makeNextChanges(with: value)
            current = next
            return next
          }
        } else {
          let first = Changes<Value>(old: nil, new: map.makeInitial(store.state))
          current = first
          return first
        }
    },
      content: content
    )

  }

  /// Initialize from `Store`
  ///
  /// - Complexity: ⚠️ No memoization
  /// - Parameters:
  ///   - store:
  ///   - content:
  public init<Store: StoreType>(
    _ store: Store,
    @ViewBuilder content: @escaping (Changes<Value>) -> Content
  ) where Value == Store.State {
    self.init(store, .map(\.root), content: content)
  }

  /// Initialize from `Store`
  ///
  /// - Complexity: ✅ Using implicit drop-input with Equatable
  /// - Parameters:
  ///   - store:
  ///   - content:
  public init<Store: StoreType>(
    _ store: Store,
    @ViewBuilder content: @escaping (Changes<Value>) -> Content
  ) where Value == Store.State, Value : Equatable {
    self.init(store, .map(\.root), content: content)
  }

  /// Initialize from `Derived`
  ///
  /// - Complexity: Depends on the map parameter
  /// - Parameters:
  ///   - derived:
  ///   - content:
  public init<Derived: DerivedType>(
    _ derived: Derived,
    _ map: MemoizeMap<Changes<Derived.Value>, Value>,
    @ViewBuilder content: @escaping (Changes<Value>) -> Content
  ) {
    self.init(derived.asDerived().innerStore, map, content: content)
  }

  /// Initialize from `Derived`
  ///
  /// - Complexity: ⚠️ No memoization
  /// - Parameters:
  ///   - derived:
  ///   - content:
  public init<Derived: DerivedType>(
    _ derived: Derived,
    @ViewBuilder content: @escaping (Changes<Value>) -> Content
  ) where Value == Derived.Value {
    self.init(derived, .map(\.root), content: content)
  }

  /// Initialize from `Derived`
  ///
  /// - Complexity: ✅ Using implicit drop-input with Equatable
  /// - Parameters:
  ///   - derived:
  ///   - content:
  public init<Derived: DerivedType>(
    _ derived: Derived,
    @ViewBuilder content: @escaping (Changes<Value>) -> Content
  ) where Value == Derived.Value, Value : Equatable {
    self.init(derived, .map(\.root), content: content)
  }


}

#endif
