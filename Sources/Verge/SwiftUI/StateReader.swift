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

/**
 A descriptor view that indicates what reads state value from Store/Derived.
 */
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct StateReader<Value: Equatable, Content: View>: View {

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
  @inline(__always)
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
  /// - Parameters:
  ///   - store:
  ///   - content:
  public init<Store: StoreType>(
    _ store: Store,
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

}

extension StateReader {
 
  public init<Store: StoreType, Pipeline: PipelineType>(
    _ store: Store,
    _ pipeline: Pipeline,
    @ViewBuilder content: @escaping (Changes<Value>) -> Content
  ) where Pipeline.Input == Changes<Store.State>, Pipeline.Output == Value {
    
    let derived = store.derived(pipeline, queue: .passthrough)
    
    self.init(derived, content: content)    
  }

}

#endif
