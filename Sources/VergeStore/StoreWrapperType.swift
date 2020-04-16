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

/**
 A protocol that wraps Store inside and provides the functions of DispatcherType
 
 Especially, it would be helpful to migrate from Verge classic.
 
 ```
 class MyViewModel: StoreWrapperType {
 
   // Current restriction, you need put the typealias as Scope points to State.
   typealias Scope = State
   
   struct State: StateType {
     ...
   }
   
   enum Activity {
     ...
   }
   
   let store: Store<State, Activity>
 
   init() {
     self.store = .init(initialState: .init(), logger: nil)
   }
 
 }
 ``` 
 */
public protocol StoreWrapperType: DispatcherType {
  
  associatedtype WrappedStore
  var store: WrappedStore { get }
}

extension StoreWrapperType {
      
  public var changes: Changes<WrappedStore.State> {
    store.asStore().changes
  }
  
  public var state: WrappedStore.State {
    store.state
  }
  
  @discardableResult
  public func subscribeStateChanges(_ receive: @escaping (Changes<WrappedStore.State>) -> Void) -> ChangesSubscription {
    store.asStore().subscribeStateChanges(receive)
  }
  
  @discardableResult
  public func subscribeActivity(_ receive: @escaping (WrappedStore.Activity) -> Void) -> ActivitySusbscription  {
    store.asStore().subscribeActivity(receive)
  }
  
  public func removeStateChangesSubscription(_ subscription: ChangesSubscription) {
    store.asStore().removeStateChangesSubscription(subscription)
  }
  
  public func removeActivitySubscription(_ subscription: ActivitySusbscription) {
    store.asStore().removeActivitySubscription(subscription)
  }
  
}

