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

/**
 Dispatcher allows us to update the state of the Store from away the store and to manage dependencies to create Mutation.
 */
open class ScopedDispatcherBase<State, Activity, Scope>: DispatcherType {

  /// A writable key path to shortly read and modify the state
  public let scope: WritableKeyPath<State, Scope>

  /// A target store which Dispatcher uses.
  public let store: Store<State, Activity>

  /// A state that cut out from root-state with the scope key path.
  public var state: Changes<Scope> {
    store.state.map { $0[keyPath: scope] }
  }
  
  /// Returns current state from target store
  public var rootState: Changes<State> {
    return store.state
  }
   
  private var logger: StoreLogger? {
    store.logger
  }
  
  let name: String
  
  public init(
    name: String? = nil,
    targetStore: Store<State, Activity>,
    scope: WritableKeyPath<State, Scope>,
    _ file: StaticString = #file,
    _ line: UInt = #line
  ) {
    self.store = targetStore
    self.scope = scope
    self.name = name ?? "\(file):\(line)"
      
    let log = DidCreateDispatcherLog(storeName: targetStore.name, dispatcherName: self.name)
    logger?.didCreateDispatcher(log: log, sender: self)

  }

  deinit {
    let log = DidDestroyDispatcherLog(storeName: store.name, dispatcherName: name)
    logger?.didDestroyDispatcher(log: log, sender: self)
  }
    
}

/**
 Dispatcher allows us to update the state of the Store from away the store and to manage dependencies to create Mutation.
 */
open class DispatcherBase<State, Activity>: ScopedDispatcherBase<State, Activity, State> {
      
  public init(
    targetStore: Store<State, Activity>
  ) {
    super.init(targetStore: targetStore, scope: \State.self)
  }
  
}

