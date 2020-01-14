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
@_exported import VergeStore
import VergeCore
#endif

open class StandaloneVergeViewModelBase<State, Activity>: StoreBase<State, Activity> {
}

open class VergeViewModelBase<State, StoreState, Activity, StoreActivity>: StandaloneVergeViewModelBase<State, Activity> {
    
  public let parent: StoreBase<StoreState, StoreActivity>
  private var subscription: EventEmitterSubscribeToken?
  
  public init(
    initialState: State,
    parent: StoreBase<StoreState, StoreActivity>,
    logger: VergeStoreLogger?
  ) {
    
    self.parent = parent
    
    super.init(initialState: initialState, logger: logger)
    
    self.subscription = parent._backingStorage.addDidUpdate { [weak self] (state) in
      guard let self = self else { return }
      self._backingStorage.update { s in
        self.updateState(state: &s, by: state)
      }
    }
    
  }
  
  deinit {
    if let subscription = self.subscription {
      parent._backingStorage.remove(subscribe: subscription)
    }
  }
  
  /// Tells you Store's state has been updated.
  /// It also called when initialized
  ///
  /// - Parameter storeState:
  open func updateState(state: inout State, by storeState: StoreState) {
    
  }
  
  open func receiveStoreActivity(_ activity: StoreActivity) {
    
  }
  
}
