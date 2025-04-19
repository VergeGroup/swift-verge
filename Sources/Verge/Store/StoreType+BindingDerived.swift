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

private enum CommitFromBindingDerived: TransactionKey {
  static var defaultValue: Bool { false }
}

extension Transaction {

  var isFromBindingDerived: Bool {
    get {
      self[CommitFromBindingDerived.self]
    }
    set {
      self[CommitFromBindingDerived.self] = newValue
    }
  }

}

private struct BindingDerivedPipeline<Source, Output, BackingPipeline: PipelineType>: PipelineType where BackingPipeline.Input == StateWrapper<Source>, BackingPipeline.Output == Output {

  typealias Input = StateWrapper<Source>

  private let backingPipeline: BackingPipeline

  init(backingPipeline: BackingPipeline) {
    self.backingPipeline = backingPipeline
  }

  func makeStorage() -> BackingPipeline.Storage {
    backingPipeline.makeStorage()
  }

  func yield(_ input: Input, storage: inout Storage) -> Output {
    backingPipeline.yield(input, storage: &storage)
  }

  func yieldContinuously(_ input: Input, storage: inout Storage) -> ContinuousResult<Output> {
    if input.transaction.isFromBindingDerived {
      return .noUpdates
    }
    return backingPipeline.yieldContinuously(input, storage: &storage)
  }

}

extension StoreDriverType {

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
    set: sending @escaping @Sendable (inout TargetStore.State, Pipeline.Output) -> Void,
    queue: some TargetQueueType = .passthrough
  ) -> BindingDerived<Pipeline.Output> where Pipeline.Input == StateWrapper<TargetStore.State> {

    let derived = BindingDerived<Pipeline.Output>.init(
      get: BindingDerivedPipeline(backingPipeline: pipeline),
      set: { [weak self] state in       
        self?.store.asStore()
          ._receive_sending { inoutRef, transaction in
            transaction.isFromBindingDerived = true
            set(&inoutRef, state)
          }
      },
      initialUpstreamState: store.asStore().stateWrapper,
      subscribeUpstreamState: { callback in
        store.asStore()._base_primitive_sinkState(
          dropsFirst: true,
          queue: queue,
          receive: callback
        )
      },
      retainsUpstream: nil
    )

    store.asStore().onDeinit { [weak derived] in
      derived?.invalidate()
    }

    return derived
  }

  public func bindingDerived<Select>(    
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    select: WritableKeyPath<TargetStore.State, Select> & Sendable,
    queue: some TargetQueueType = .passthrough
  ) -> BindingDerived<Select> {

    bindingDerived(
      name, file, function, line,
      get: .select(select),
      set: { state, newValue in
        state[keyPath: select] = newValue
      },
      queue: queue
    )
  }
  
  public func bindingDerived<Select: Equatable>(    
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    select: WritableKeyPath<TargetStore.State, Select> & Sendable,
    queue: some TargetQueueType = .passthrough
  ) -> BindingDerived<Select> {
    
    bindingDerived(
      name, file, function, line,
      get: .select(select),
      set: { state, newValue in
        state[keyPath: select] = newValue
      },
      queue: queue
    )
  }

}

