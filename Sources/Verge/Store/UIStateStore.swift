//
// Copyright (c) 2021 muukii
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

/// A store that optimized for only using in UI thread.
/// No using locks.
@MainActor
public final class UIStateStore<State: Equatable, Activity>: Store<State, Activity> {

  public nonisolated init(
    initialState: State,
    logger: StoreLogger? = nil
  ) {
    super.init(
      initialState: initialState,
      storeOperation: .nonAtomic,
      logger: logger
    )
  }

}

@propertyWrapper
@MainActor
public struct UIState<State: Equatable>: Sendable {

  private let store: UIStateStore<State, Never>

  public nonisolated init(wrappedValue: State) {
    self.store = .init(initialState: wrappedValue)
  }

  // MARK: - PropertyWrapper

  public var wrappedValue: State {
    get { store.primitiveState }
    nonmutating set {
      store.commit {
        $0.replace(with: newValue)
      }
    }
  }

  public var projectedValue: UIStateStore<State, Never> {
    return store
  }
  
}

@propertyWrapper
public struct AtomicState<State: Equatable>: Sendable {
  
  private let store: Store<State, Never>
  
  public nonisolated init(wrappedValue: State) {
    self.store = .init(initialState: wrappedValue)
  }
  
  // MARK: - PropertyWrapper
  
  public var wrappedValue: State {
    get { store.primitiveState }
    nonmutating set {
      store.commit {
        $0.replace(with: newValue)
      }
    }
  }
  
  public var projectedValue: Store<State, Never> {
    return store
  }
  
}
