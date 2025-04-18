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
import TypedComparator

public enum ContinuousResult<Output> {
  case new(Output)
  case noUpdates
}

extension ContinuousResult: Equatable where Output: Equatable {

}

/// A filter object that yields the output produced from the input.
public protocol PipelineType<Input, Output>: Sendable {

  associatedtype Input
  associatedtype Output
  associatedtype Storage = Void

  func makeStorage() -> Storage

  /// Yields the output from the input.
  func yield(_ input: Input, storage: inout Storage) -> Output

  /// Yields the output from the input if it's needed
  func yieldContinuously(_ input: Input, storage: inout Storage) -> ContinuousResult<Output>

}

extension PipelineType where Storage == Void {
  public func makeStorage() {
    ()
  }
}

/// It produces outputs from inputs with their own conditions.
///
/// Against just using map closure, it can drop output if there are no changes.
/// This will be helpful in performance. Therefore most type parameters require Equatable.
public enum Pipelines {

  /// KeyPath based pipeline, light weight operation just take value from source.
  public struct ChangesSelectPassthroughPipeline<Source: Sendable, Output>: PipelineType {

    public typealias Storage = Void

    public typealias Input = StateWrapper<Source>

    public let selector: @Sendable (borrowing Input.State) -> Output

    public init(
      selector: @escaping @Sendable (borrowing Input.State) -> Output
    ) {
      self.selector = selector
    }

    public func yieldContinuously(_ input: Input, storage: inout Storage) -> ContinuousResult<Output> {

      let target = selector(input.state)

      return .new(consume target)

    }

    public func yield(_ input: Input, storage: inout Storage) -> Output {
      selector(input.state)
    }

  }

  /// KeyPath based pipeline, light weight operation just take value from source.
  public struct ChangesSelectPipeline<Source: Sendable, Output: Equatable>: PipelineType {

    public typealias Input = StateWrapper<Source>
    public typealias Storage = Output?

    public let selector: @Sendable (borrowing Input.State) -> Output
    public let additionalDropCondition: (@Sendable (Input.State) -> Bool)?

    public init(
      selector: @escaping @Sendable (borrowing Input.State) -> Output,
      additionalDropCondition: (@Sendable (Input.State) -> Bool)?
    ) {
      self.selector = selector
      self.additionalDropCondition = additionalDropCondition
    }

    public func makeStorage() -> Storage {
      nil
    }

    public func yieldContinuously(_ input: Input, storage: inout Storage) -> ContinuousResult<Output> {

      if let additionalDropCondition = additionalDropCondition, additionalDropCondition(input.state) {
        return .noUpdates
      }
      
      let target = selector(input.state)
      
      if let previousValue = storage, previousValue == target {
        return .noUpdates
      }
      
      storage = target
      
      return .new(consume target)
    }

    public func yield(_ input: Input, storage: inout Storage) -> Output {
      let output = selector(input.state)
      storage = output
      return output
    }

    public func drop(while predicate: @escaping @Sendable (Input.State) -> Bool) -> Self {
      return .init(
        selector: selector,
        additionalDropCondition: additionalDropCondition.map { currentCondition in
          { input in
            currentCondition(input) || predicate(input)
          }
        } ?? predicate
      )
    }
  }

  public struct UniqueFilterEquatable<Map: MapFunction>: PipelineType where Map.Output: Equatable {

    public typealias Input = Map.Input
    public typealias Output = Map.Output

    private let map: Map

    public init(map: Map) {
      self.map = map
    }

    public func makeStorage() -> VergeConcurrency.UnfairLockAtomic<Output?> {
      .init(nil)
    }

    public func yield(_ input: Input, storage: inout Storage) -> Output {
      let result = map.perform(input)
      storage.swap(result)
      return result
    }

    public func yieldContinuously(_ input: Input, storage: inout Storage) -> ContinuousResult<Output> {

      // not to check if input has changed because storing the input may cause performance issue by copying.

      let result = map.perform(input)

      return storage.modify { value in
        if value != result {
          value = result
          return .new(result)
        } else {
          return .noUpdates
        }
      }
    }

  }

  public struct UniqueFilter<Map: MapFunction, OutputComparator: TypedComparator>: PipelineType
  where OutputComparator.Input == Map.Output? {

    public typealias Input = Map.Input
    public typealias Output = Map.Output

    private let map: Map
    private let outputComparator: OutputComparator

    public init(map: Map, outputComparator: OutputComparator) {
      self.map = map
      self.outputComparator = outputComparator
    }

    public func makeStorage() -> VergeConcurrency.UnfairLockAtomic<Output?> {
      .init(nil)
    }

    public func yield(_ input: Input, storage: inout Storage) -> Output {
      let result = map.perform(input)
      storage.swap(result)
      return result
    }

    public func yieldContinuously(_ input: Input, storage: inout Storage) -> ContinuousResult<Output> {

      // not to check if input has changed because storing the input may cause performance issue by copying.

      let result = map.perform(input)

      return storage.modify { value in
        if !outputComparator(value, result) {
          value = result
          return .new(result)
        } else {
          return .noUpdates
        }
      }
    }

  }

}

public protocol MapFunction: Sendable {
  associatedtype Input
  associatedtype Output
  func perform(_ input: Input) -> Output
}

public struct AnyMapFunction<Input, Output>: MapFunction {

  private let _perform: @Sendable (Input) -> Output

  public init(_ perform: @escaping @Sendable (Input) -> Output) {
    self._perform = perform
  }

  public func perform(_ input: Input) -> Output {
    _perform(input)
  }
}

extension PipelineType {

  public static func uniqueMap<Map: MapFunction>(_ mapFunction: Map) -> Self
  where Map.Output: Equatable, Self == Pipelines.UniqueFilterEquatable<Map> {
    return .init(map: mapFunction)
  }

  public static func uniqueMap<Input, Output: Equatable>(
    _ map: @escaping @Sendable (Input) -> Output
  ) -> Self
  where Output: Equatable, Self == Pipelines.UniqueFilterEquatable<AnyMapFunction<Input, Output>> {
    return uniqueMap(.init(map))
  }

  public static func uniqueMap<Map: MapFunction, OutputComparator: TypedComparator>(
    _ mapFunction: Map, _ outputComparator: OutputComparator
  ) -> Self
  where Self == Pipelines.UniqueFilter<Map, OutputComparator> {
    return .init(map: mapFunction, outputComparator: outputComparator)
  }

  public static func uniqueMap<Input, Output, OutputComparator: TypedComparator>(
    _ map: @escaping @Sendable (Input) -> Output, _ outputComparator: OutputComparator
  ) -> Self
  where Self == Pipelines.UniqueFilter<AnyMapFunction<Input, Output>, OutputComparator> {
    return .init(map: .init(map), outputComparator: outputComparator)
  }

}

extension PipelineType {

  /**
   For Changes input
   Produces output values using KeyPath-based projection.

   exactly same with ``PipelineType/select(_:)``
   */
  public static func map<Input, Output>(
    _ selector: @escaping @Sendable (
      borrowing Input
    ) -> Output
  ) -> Self
  where Output: Equatable, Self == Pipelines.ChangesSelectPipeline<Input, Output> {
    self.init(selector: selector, additionalDropCondition: nil)
  }

  /**
   For Changes input
   Produces output values using KeyPath-based projection.

   exactly same with ``PipelineType/select(_:)``
   */
  public static func map<Input, Output>(
    _ selector: @escaping @Sendable (
      borrowing Input
    ) -> Output
  ) -> Self
  where Self == Pipelines.ChangesSelectPassthroughPipeline<Input, Output> {
    self.init(selector: selector)
  }

  /**
   For Changes input
   Produces output values using closure based projection.

   exactly same with ``PipelineType/map(_:)-7xvom``
   */
  // needs this overload as making closure from keyPath will not make sendable closure.
  public static func map<Input, Output>(
    _ selector: KeyPath<Input, Output> & Sendable
  ) -> Self
  where Output: Equatable, Self == Pipelines.ChangesSelectPipeline<Input, Output> {
    self.init(selector: { $0[keyPath: selector] }, additionalDropCondition: nil)
  }

  /**
   For Changes input
   Produces output values using closure based projection.

   exactly same with ``PipelineType/map(_:)-7xvom``
   */
  public static func select<Input, Output: Equatable>(
    _ selector: KeyPath<Input, Output> & Sendable
  ) -> Self
  where Output: Equatable, Self == Pipelines.ChangesSelectPipeline<Input, Output> {
    self.init(selector: { $0[keyPath: selector] }, additionalDropCondition: nil)
  }
  
  /**
   For Changes input
   Produces output values using closure based projection.
   
   exactly same with ``PipelineType/map(_:)-7xvom``
   */
  public static func select<Input, Output>(
    _ selector: KeyPath<Input, Output> & Sendable
  ) -> Self
  where Self == Pipelines.ChangesSelectPassthroughPipeline<Input, Output> {
    self.init(selector: { $0[keyPath: selector] })
  }
  
}
