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

extension StoreDriverType {

  public typealias Assignee<Value> = @Sendable (Value) -> Void

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
    _ keyPath: WritableKeyPath<TargetStore.State, Value> & Sendable,
    dropsOutput: @escaping @Sendable (Changes<Value>) -> Bool = { _ in false }
  ) -> Assignee<Changes<Value>> {
    return { [weak store] value in
      guard !dropsOutput(value) else { return }
      store?.asStore().commit {
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
  public func assignee<Value>(
    _ keyPath: WritableKeyPath<TargetStore.State, Value?> & Sendable,
    dropsOutput: @escaping @Sendable (Changes<Value?>) -> Bool = { _ in false }
  ) -> Assignee<Changes<Value?>> {
    return { [weak store] value in
      guard !dropsOutput(value) else { return }
      store?.asStore().commit {
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
  public func assignee<Value>(
    _ keyPath: WritableKeyPath<TargetStore.State, Value?> & Sendable,
    dropsOutput: @escaping @Sendable (Changes<Value?>) -> Bool = { _ in false }
  ) -> Assignee<Changes<Value>> {
    return { [weak store] value in
      let changes = value.map { Optional.some($0) }
      guard !dropsOutput(changes) else { return }
      store?.asStore().commit {
        $0[keyPath: keyPath] = .some(value.primitive)
      }
    }
  }

  /**
   Assignee to asign Changes object directly.
   */
  public func assignee<Value>(
    _ keyPath: WritableKeyPath<TargetStore.State, Value> & Sendable
  ) -> Assignee<Value> {
    return { [weak store] value in
      store?.asStore().commit {
        $0[keyPath: keyPath] = value
      }
    }
  }

  /**
   Assignee to asign Changes object directly.
   */
  public func assignee<Value>(
    _ keyPath: WritableKeyPath<TargetStore.State, Value?> & Sendable
  ) -> Assignee<Value?> {
    return { [weak store] value in
      store?.asStore().commit { [value] a in        
        a[keyPath: keyPath] = value
      }
    }
  }

  /**
   Assignee to asign Changes object directly.
   */
  public func assignee<Value>(
    _ keyPath: WritableKeyPath<TargetStore.State, Value?> & Sendable
  ) -> Assignee<Value> {
    return { [weak store] value in
      store?.asStore().commit {
        $0[keyPath: keyPath] = .some(value)
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
    _ keyPath: WritableKeyPath<TargetStore.State, Value> & Sendable
  ) -> Assignee<Changes<Value>> {
    assignee(keyPath, dropsOutput: { !$0.hasChanges })
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
    _ keyPath: WritableKeyPath<TargetStore.State, Value?> & Sendable
  ) -> Assignee<Changes<Value?>> {
    assignee(keyPath, dropsOutput: { !$0.hasChanges })
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
    _ keyPath: WritableKeyPath<TargetStore.State, Value?> & Sendable
  ) -> Assignee<Changes<Value>> {
    assignee(keyPath, dropsOutput: { !$0.hasChanges })
  }

}
