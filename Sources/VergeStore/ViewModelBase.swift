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
import VergeCore
#endif

@available(*, deprecated, renamed: "StoreBase")
open class StandaloneVergeViewModelBase<State: StateType, Activity>: StoreBase<State, Activity> {
}

open class ViewModelBase<State: StateType, Activity, ParentState: StateType, ParentActivity>: StoreBase<State, Activity> {
    
  public let parent: StoreBase<ParentState, ParentActivity>
  private var parentStateSubscription: EventEmitterSubscribeToken?
  private var parentActivitySubscription: EventEmitterSubscribeToken?
  
  public init(
    initialState: State,
    parent: StoreBase<ParentState, ParentActivity>,
    logger: StoreLogger?
  ) {
    
    self.parent = parent
    
    super.init(initialState: initialState, logger: logger)
    
    self.parentStateSubscription = parent._backingStorage.addDidUpdate { [weak self] (state) in
      guard let self = self else { return }
      self._backingStorage.update { s in
        self.updateState(state: &s, by: state)
      }
    }
        
    self.parentActivitySubscription = parent._eventEmitter.add { [weak self] (activity) in
      guard let self = self else { return }
      self.receiveParentActivity(activity)
    }
        
  }
  
  deinit {
    if let subscription = self.parentStateSubscription {
      parent._backingStorage.remove(subscription)
    }
    if let subscription = self.parentActivitySubscription {
      parent._eventEmitter.remove(subscription)
    }
  }
  
  /// Override method
  /// Tells you Store's state has been updated.
  /// It also called when initialized
  ///
  /// - Parameter storeState:
  open func updateState(state: inout State, by parentState: ParentState) {
  }
  
  /// Override method
  open func receiveParentActivity(_ activity: ParentActivity) {
   
  }
  
}

extension StoreBase {
  
  #if COCOAPODS
  public typealias ViewModelBase<_State: StateType, _Activity> = Verge.ViewModelBase<_State, _Activity, State, Activity>
  #else
  public typealias ViewModelBase<_State: StateType, _Activity> = VergeStore.ViewModelBase<_State, _Activity, State, Activity>
  #endif
}
