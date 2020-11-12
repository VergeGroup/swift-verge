//
// Copyright (c) 2020 Hiroshi Kimura(Muukii) <muukii.app@gmail.com>
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

@available(*, deprecated, message: "Please use StateReader instead.")
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public typealias UseState<Value, Content: View> = _StateReaderContent<Value, Content>

/**
 A descriptor view that indicates what reads state value from Store/Derived.
 
 It doesn't have content-view still.
 Make sure it owning content-view with calling `.content()`.
 */
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct StateReader<Value>: View {

  private let observableObject: _VergeObservableObjectBase
  private let updateValue: () -> Changes<Value>

  fileprivate init(
    updateTrigger: _VergeObservableObjectBase,
    updateValue: @escaping () -> Changes<Value>
  ) {
    self.observableObject = updateTrigger
    self.updateValue = updateValue
  }

  public var body: EmptyView {
    assertionFailure("""
      Warning: StateReader still does not have a content-view.
      Please add a content by `.content()`.

      This issue comes from current auto-completion function doesn't work well.
      Probably, it's might be fixed with better syntax.
      """)
    return EmptyView()
  }

  /**
   Makes itself having content.

   This syntax and approach are related to the lacking of current Xcode's auto-completion. (Xcode12)
   */
  public func content<NewContent: View>(@ViewBuilder _ makeContent: @escaping (Changes<Value>) -> NewContent) -> _StateReaderContent<Value, NewContent> {
    return .init(updateTrigger: observableObject, updateValue: updateValue, content: makeContent)
  }

  @available(*, deprecated, message: "You're returning a value which is not a type of `SwiftUI.View`.")
  public func content(@ViewBuilder _ makeContent: @escaping (Changes<Value>) -> Never) -> Never {
    fatalError()
  }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct _StateReaderContent<Value, Content: View>: View {

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
extension StateReader {

  /// inner init
  private init<Derived: DerivedType>(
    derived: Derived
  ) where Value == Derived.Value {

    let concrete = derived.asDerived()

    self.init(
      updateTrigger: concrete,
      updateValue: {
        concrete.value
      }
    )

  }

  /// Creates an instance from `Store`
  ///
  /// - Complexity: ⚠️ No memoization, content closure runs every time according to the store's updates.
  /// - Parameters:
  ///   - store:
  ///   - content:
  public init<Store: StoreType>(
    _ store: Store
  ) where Value == Store.State {

    let store = store.asStore()

    self.init(
      updateTrigger: store,
      updateValue: {
        store.state
      }
    )

  }

  /// Creates an instance  from `Derived`
  ///
  /// - Complexity: 💡 It depends on how Derived does memoization.
  /// - Parameters:
  ///   - derived:
  ///   - content:
  public init<Derived: DerivedType>(
    _ derived: Derived
  ) where Value == Derived.Value {

    self.init(derived: derived)

  }

  /// Initialize from `Store`
  ///
  /// - Complexity: ✅ Using implicit drop-input with Equatable
  /// - Parameters:
  ///   - store:
  ///   - content:
  public init<Store: StoreType>(
    _ store: Store
  ) where Value == Store.State, Value : Equatable {
    self.init(store.derived(.map(\.root)))
  }

  /// Initialize from `Store`
  ///
  /// - Complexity: ✅ Using implicit drop-input with Equatable
  /// - Parameters:
  ///   - store:
  ///   - content:
  public init<Derived: DerivedType>(
    _ derived: Derived
  ) where Value == Derived.Value, Value : Equatable {
    assert(derived.asDerived().attributes.contains(.dropsDuplicatedOutput) == true)
    self.init(derived: derived)
  }

}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension _StateReaderContent {

  /// inner init
  private init<Derived: DerivedType>(
    derived: Derived,
    @ViewBuilder content: @escaping (Changes<Derived.Value>) -> Content
  ) where Value == Derived.Value {

    let concrete = derived.asDerived()

    self.init(
      updateTrigger: concrete,
      updateValue: {
        concrete.value
      },
      content: content
    )

  }

  /// Initialize from `Store`
  ///
  /// - Complexity: ⚠️ No memoization, content closure runs every time according to the store's updates.
  /// - Parameters:
  ///   - store:
  ///   - content:
  public init<Store: StoreType>(
    store: Store,
    @ViewBuilder content: @escaping (Changes<Store.State>) -> Content
  ) where Value == Store.State {

    let store = store.asStore()

    self.init(
      updateTrigger: store,
      updateValue: {
        store.state
      },
      content: content
    )

  }

  /// Creates an instance  from `Derived`
  ///
  /// - Complexity: 💡 It depends on how Derived does memoization.
  /// - Parameters:
  ///   - derived:
  ///   - content:
  public init<Derived: DerivedType>(
    _ derived: Derived,
    @ViewBuilder content: @escaping (Changes<Derived.Value>) -> Content
  ) where Value == Derived.Value {

    self.init(derived: derived, content: content)
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
    self.init(store.derived(.map(\.root)), content: content)
  }

  /// Initialize from `Store`
  ///
  /// - Complexity: ✅ Using implicit drop-input with Equatable
  /// - Parameters:
  ///   - store:
  ///   - content:
  public init<Derived: DerivedType>(
    _ derived: Derived,
    @ViewBuilder content: @escaping (Changes<Value>) -> Content
  ) where Value == Derived.Value, Value : Equatable {
    assert(derived.asDerived().attributes.contains(.dropsDuplicatedOutput) == true)
    self.init(derived: derived, content: content)

  }

}

#endif
