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

public protocol DispacherContextType {
  associatedtype Dispatcher: DispatcherType
  var dispatcher: Dispatcher { get }
}

/// A context object created from an action.
/// - Attention: This object retains owner. you may need to be weakify context object.
public final class ContextualDispatcher<Dispatcher: DispatcherType, Scope>: DispacherContextType, DispatcherType {
      
  public typealias Activity = Dispatcher.Activity
  
  public typealias State = Dispatcher.State
    
  public let scope: WritableKeyPath<Dispatcher.State, Scope>
  
  public let metadata: DispatcherMetadata
  
  /// Target dispatcher
  public let dispatcher: Dispatcher
  
  @available(*, deprecated, renamed: "targetStore")
  public var target: Store<Dispatcher.State, Dispatcher.Activity> {
    targetStore
  }
  
  public var targetStore: Store<Dispatcher.State, Dispatcher.Activity> {
    dispatcher.target
  }
  
  /// Returns current state from target store
  public var state: Scope {
    return dispatcher.target.state[keyPath: scope]
  }
            
  /// Returns current state from target store
  public var rootState: State {
    return dispatcher.target.state
  }
  
  init(
    scope: WritableKeyPath<Dispatcher.State, Scope>,
    dispatcher: Dispatcher,
    actionMetadata: ActionMetadata
  ) {
    self.scope = scope
    self.dispatcher = dispatcher
    self.metadata = .init(fromAction: actionMetadata)
  }
     
}

var keyForIsRedirecting: String { "me.muukii.verge.IsRedirecting" }

var contextMetadataRedirectingOnCrrentThread: DispatcherMetadata? {
  Thread.current.threadDictionary.object(forKey: keyForIsRedirecting) as? DispatcherMetadata
}

func enterRedirectingOnCurrentThread(metadata: DispatcherMetadata) {
  Thread.current.threadDictionary.setValue(metadata, forKey: keyForIsRedirecting)
}

func leaveRedirectingOnCurrentThread() {
  Thread.current.threadDictionary.setValue(nil, forKey: keyForIsRedirecting)
}

extension ContextualDispatcher {
         
  public func redirect<Result>(_ redirect: (Dispatcher) throws -> Result) rethrows -> Result {
    
    enterRedirectingOnCurrentThread(metadata: metadata)
    
    defer {
      leaveRedirectingOnCurrentThread()
    }
    return try redirect(dispatcher)
  }

}
