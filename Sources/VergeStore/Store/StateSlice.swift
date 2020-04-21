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

public class StateSlice<State> {
        
  /// A current state.
  public var state: State {
    innerStore.state
  }
  
  /// A current changes state.
  public var changes: Changes<State> {
    innerStore.changes
  }
  
  fileprivate let innerStore: Store<State, Never>
      
  fileprivate let _set: (State) -> Void
    
  public init<Source: StoreType>(
    get: ConditionalMap<Changes<Source.State>, State>,
    set: @escaping (inout Source.State, State) -> Void,
    source: Source
  ) {
    
    let store = Store<State, Never>.init(initialState: get.makeInitial(source.asStore().changes), logger: nil)
    
    source.asStore().subscribeStateChanges(dropsFirst: true) { [weak store] (changes) in
      let update = get.map(changes)
      switch update {
      case .noChanages:
        break
      case .updated(let newState):
        store?.commit {
          $0 = newState
        }
      }
    }
    
    self.innerStore = store
    self._set = { [weak source] state in
      source?.asStore().commit {
        set(&$0, state)
      }
    }
  }
  
  /// Subscribe the state changes
  ///
  /// - Returns: Token to remove suscription if you need to do explicitly. Subscription will be removed automatically when Store deinit
  @discardableResult
  public func subscribeStateChanges(_ receive: @escaping (Changes<State>) -> Void) -> ChangesSubscription {
    
    innerStore.subscribeStateChanges { (changes) in
      receive(changes)
    }
  }
  
}

public final class BindingStateSlice<State>: StateSlice<State> {
  
  /// A current state.
  public override var state: State {
    get {
      innerStore.state
    }
    set {
      _set(newValue)
    }
  }
  
}
