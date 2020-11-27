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

extension StoreType {

  public typealias Assignee<Value> = (Value) -> Void

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
  ) -> Assignee<Changes<Value>> {
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
  public func assignee<Value>(
    _ keyPath: WritableKeyPath<State, Value?>,
    dropsOutput: @escaping (Changes<Value?>) -> Bool = { _ in false }
  ) -> Assignee<Changes<Value?>> {
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
  public func assignee<Value>(
    _ keyPath: WritableKeyPath<State, Value?>,
    dropsOutput: @escaping (Changes<Value?>) -> Bool = { _ in false }
  ) -> Assignee<Changes<Value>> {
    return { [weak self] value in
      let changes = value.map { Optional.some($0) }
      guard !dropsOutput(changes) else { return }
      self?.asStore().commit {
        $0[keyPath: keyPath] = .some(value.primitive)
      }
    }
  }

  /**
   Assignee to asign Changes object directly.
   */
  public func assignee<Value>(
    _ keyPath: WritableKeyPath<State, Value>
  ) -> Assignee<Value> {
    return { [weak self] value in
      self?.asStore().commit {
        $0[keyPath: keyPath] = value
      }
    }
  }

  /**
   Assignee to asign Changes object directly.
   */
  public func assignee<Value>(
    _ keyPath: WritableKeyPath<State, Value?>
  ) -> Assignee<Value?> {
    return { [weak self] value in
      self?.asStore().commit {
        $0[keyPath: keyPath] = value
      }
    }
  }

  /**
   Assignee to asign Changes object directly.
   */
  public func assignee<Value>(
    _ keyPath: WritableKeyPath<State, Value?>
  ) -> Assignee<Value> {
    return { [weak self] value in
      self?.asStore().commit {
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
    _ keyPath: WritableKeyPath<State, Value>
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
    _ keyPath: WritableKeyPath<State, Value?>
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
    _ keyPath: WritableKeyPath<State, Value?>
  ) -> Assignee<Changes<Value>> {
    assignee(keyPath, dropsOutput: { !$0.hasChanges })
  }

}
