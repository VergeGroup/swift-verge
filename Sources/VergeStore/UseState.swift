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
@available(iOS 13.0, macOS 10.15, *)
public struct UseState<StateProvider: _VergeObservableObjectBase, Content: View>: View {

  @ObservedObject private var observableObject: StateProvider
  private let content: (StateProvider) -> Content

  public var body: some View {
    content(observableObject)
  }

}

@available(iOS 13.0, macOS 10.15, *)
extension UseState where StateProvider : StoreType {

  /// Initialize from `Store`
  /// - Parameters:
  ///   - store:
  ///   - content:
  public init(
    _ store: StateProvider,
    @ViewBuilder content: @escaping (StateProvider) -> Content
  ) {
    self.content = content
    self.observableObject = store
  }

}

@available(iOS 13.0, macOS 10.15, *)
extension UseState where StateProvider : DerivedType {

  /// Initialize from `Derived`
  /// - Parameters:
  ///   - derived:
  ///   - content: 
  public init(
    _ derived: StateProvider,
    @ViewBuilder content: @escaping (StateProvider) -> Content
  ) {
    self.content = content
    self.observableObject = derived
  }

}

#endif
