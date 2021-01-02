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

import class Foundation.NSString

extension StoreType {

  /// Returns Binding Derived object
  ///
  /// - Complexity: 💡 It's better to set `dropsOutput` predicate.
  /// - Parameters:
  ///   - name:
  ///   - get:
  ///   - dropsOutput: Predicate to drops object if found a duplicated output
  ///   - set:
  /// - Returns:
  public func binding<NewState>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    get: Pipeline<Changes<State>, NewState>,
    dropsOutput: @escaping (Changes<NewState>) -> Bool = { _ in false },
    set: @escaping (inout InoutRef<State>, NewState) -> Void,
    queue: TargetQueue = .passthrough
  ) -> BindingDerived<NewState> {

    let derived = BindingDerived<NewState>.init(
      get: get,
      set: { [weak self] state in
        self?.asStore().commit(name, file, function, line) {
          set(&$0, state)
        }
      },
      initialUpstreamState: asStore().state,
      subscribeUpstreamState: { callback in
        asStore().sinkState(
          dropsFirst: true,
          queue: queue,
          receive: callback
        )
      }, retainsUpstream: nil)

    derived.setDropsOutput(dropsOutput)

    return derived
  }

  /// Returns Binding Derived object
  ///
  /// - Complexity: ✅ Drops duplicated the output with Equatable comparison.
  /// - Parameters:
  ///   - name:
  ///   - get:
  ///   - set:
  /// - Returns:
  public func binding<NewState>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    get: Pipeline<Changes<State>, NewState>,
    set: @escaping (inout InoutRef<State>, NewState) -> Void,
    queue: TargetQueue = .passthrough
  ) -> BindingDerived<NewState> where NewState : Equatable {

    binding(
      name,
      file,
      function,
      line,
      get: get,
      dropsOutput: { $0.asChanges().noChanges(\.root) },
      set: set,
      queue: queue
    )
  }

}

