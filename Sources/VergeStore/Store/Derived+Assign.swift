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

extension Derived {
  
  /**
   Assigns a derived's value to a property of a store.
   
   - Attention: Store won't be retained.
   */
  public func assign<Store: StoreType & DispatcherType>(
    to keyPath: WritableKeyPath<Store.State, Value>,
    on store: Store,
    dropsOutput: @escaping (Changes<Value>) -> Bool = { _ in false }
  ) -> VergeAnyCancellable where Store.State == Store.Scope {
    assign(to: store.asStore().assignee(keyPath, dropsOutput: dropsOutput))
  }
  
  /**
   Assigns a derived's value to a property of an object.
   
   - Attention: Store won't be retained.
   */
  public func assign<Object: AnyObject>(
    to keyPath: ReferenceWritableKeyPath<Object, Value>,
    on object: Object,
    dropsOutput: @escaping (Changes<Value>) -> Bool = { _ in false }
  ) -> VergeAnyCancellable {
    sinkValue { [weak object] c in
      guard !dropsOutput(c) else { return }
      object?[keyPath: keyPath] = c.primitive
    }
  }
    
}

extension Derived where Value : Equatable {
  
  /**
   Assigns a derived's value to a property of a store.
   
   - Attention: Store won't be retained.
   - Returns: a cancellable. See detail of handling cancellable from `VergeAnyCancellable`'s docs
   */
  public func assign<Store: StoreType & DispatcherType>(
    to keyPath: WritableKeyPath<Store.State, Value>,
    on store: Store
  ) -> VergeAnyCancellable where Store.State == Store.Scope {
    assign(to: store.asStore().assignee(keyPath, dropsOutput: { !$0.hasChanges }))
  }
  
  /**
   Assigns a derived's value to a property of an object.
   
   - Attention: Store won't be retained.
   */
  public func assign<Object: AnyObject>(
    to keyPath: ReferenceWritableKeyPath<Object, Value>,
    on object: Object
  ) -> VergeAnyCancellable {
    assign(to: keyPath, on: object, dropsOutput: { !$0.hasChanges })
  }
  
}

extension Derived {
  
  /**
   Assigns a derived's value to a property of a store.
   
   - Attention: Store won't be retained.
   - Returns: a cancellable. See detail of handling cancellable from `VergeAnyCancellable`'s docs
   */
  public func assign(
    to binder: @escaping (Changes<Value>) -> Void
  ) -> VergeAnyCancellable {
    sinkValue { c in
      binder(c)
    }
  }
  
}

extension StoreType {
  
  /**
   Returns an asignee function to asign
   
   ```
   let store1 = Store()
   let store2 = Store()
   
   store1
     .derived(.map(\.count))
     .assign(to: store2.assignee(\.count))
   ```
   */
  public func assignee<Value>(
    _ keyPath: WritableKeyPath<State, Value>,
    dropsOutput: @escaping (Changes<Value>) -> Bool = { _ in false }
  ) -> (Changes<Value>) -> Void {
    return { [weak self] value in
      guard !dropsOutput(value) else { return }
      self?.asStore().commit {
        $0[keyPath: keyPath] = value.primitive
      }
    }
  }
  
  /**
   Returns an asignee function to asign
   
   ```
   let store1 = Store()
   let store2 = Store()
   
   store1
     .derived(.map(\.count))
     .assign(to: store2.assignee(\.count))
   ```
   */
  public func assignee<Value: Equatable>(
    _ keyPath: WritableKeyPath<State, Value>
  ) -> (Changes<Value>) -> Void {
    assignee(keyPath, dropsOutput: { !$0.hasChanges })
  }
  
}
