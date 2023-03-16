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
  public func bindingDerived<Pipeline: PipelineType>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    get pipeline: Pipeline,
    set: @escaping (inout InoutRef<State>, Pipeline.Output) -> Void,
    queue: TargetQueueType = .passthrough
  ) -> BindingDerived<Pipeline.Output> where Pipeline.Input == Changes<State> {

    let derived = BindingDerived<Pipeline.Output>.init(
      get: pipeline,
      set: { [weak self] state in
        self?.asStore().commit(name, file, function, line) {
          set(&$0, state)
        }
      },
      initialUpstreamState: asStore().state,
      subscribeUpstreamState: { callback in
        asStore()._primitive_sinkState(
          dropsFirst: true,
          queue: queue,
          receive: callback
        )
      },
      retainsUpstream: nil
    )

    return derived
  }

  public func bindingDerived<Select>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    select: WritableKeyPath<State, Select>,
    queue: TargetQueueType = .passthrough
  ) -> BindingDerived<Select> {

    bindingDerived(
      name, file, function, line,
      get: .select(select),
      set: { state, newValue in
        state[keyPath: select] = newValue
      }
    )
  }

}

