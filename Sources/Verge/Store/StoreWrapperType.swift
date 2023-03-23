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

/**
 A protocol that wraps Store inside and provides the functions of DispatcherType
 
 Especially, it would be helpful to migrate from Verge classic.
 
 ```
 final class MyViewModel: StoreComponentType {
 
   // Current restriction, you need put the typealias as Scope points to State.
   typealias Scope = State
   
   struct State {
     ...
   }

   // If you don't need Activity, you can remove it.
   enum Activity {
     ...
   }
   
   let store: DefaultStore
 
   init() {
     self.store = .init(initialState: .init(), logger: nil)
   }
 
 }
 ``` 
 */
public protocol StoreComponentType: DispatcherType where Scope == WrappedStore.State {

  var store: WrappedStore { get }
}

/// It would be deprecated in the future.
public typealias StoreWrapperType = StoreComponentType

extension StoreComponentType {

  /// Returns a current state with thread-safety.
  ///
  /// It causes locking and unlocking with a bit cost.
  /// It may cause blocking if any other is doing mutation or reading.
  public nonisolated var state: Changes<WrappedStore.State> {
    store.state
  }

  @available(*, deprecated, renamed: "state")
  public nonisolated var changes: Changes<WrappedStore.State> {
    store.asStore().changes
  }
  
  public nonisolated var primitiveState: WrappedStore.State {
    store.primitiveState
  }
 
}

#if canImport(Combine)

import Combine

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension StoreComponentType {
  
  public func statePublisher() -> some Combine.Publisher<Changes<State>, Never> {
    store.asStore().statePublisher()
  }
  
  public func activityPublisher() -> some Combine.Publisher<Activity, Never> {
    store.asStore().activityPublisher()
  }
  
}

#endif
