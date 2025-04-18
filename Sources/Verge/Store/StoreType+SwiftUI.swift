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

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension StoreDriverType where Self : Sendable {
  
  /// Generates a SwiftUI.Binding that gets and updates the StoreType.State.
  /// Usage:
  ///
  ///     TextField("hoge", text: store.binding(\.inputingText))
  ///
  /// - Warning: Still in experimentals.
  /// - Parameters:
  ///   - keypath: A property of the state to be bound.
  ///   - mutation: A closure to update the state.
  ///   If the closure is nil, state will be automatically updated.
  /// - Returns: The result of binding
  public func binding<T>(_ keyPath: WritableKeyPath<Scope, T> & Sendable) -> SwiftUI.Binding<T> {    
    .init(
      get: { [self /* source store lives until binding released */] in
        return self.state[keyPath: keyPath]
      }, set: { [weak self] value in    
        self?.commit {
          $0[keyPath: keyPath] = value
        }
      }
    )    
  }
}

extension StoreDriverType {
  
  /// Generates a SwiftUI.Binding that gets and updates the StoreType.State.
  /// Usage:
  ///
  ///     TextField("hoge", text: store.binding(\.inputingText))
  ///
  /// - Warning: Still in experimentals.
  /// - Parameters:
  ///   - keypath: A property of the state to be bound.
  ///   - mutation: A closure to update the state.
  ///   If the closure is nil, state will be automatically updated.
  /// - Returns: The result of binding
  public nonisolated func binding<T>(_ keyPath: WritableKeyPath<Scope, T>) -> SwiftUI.Binding<T> {    
    .init(
      get: { [self /* source store lives until binding released */] in
        return self.state[keyPath: keyPath]
      }, set: { [weak self, keyPath] value in    
        self?.commit { [keyPath] in
          $0[keyPath: keyPath] = value
        }
      }
    )    
  }
  
}


#endif
