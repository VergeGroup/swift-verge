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

@available(*, deprecated, renamed: "Pipeline")
public typealias MemoizeMap<Input, Output> = Pipeline<Input, Output>

fileprivate let counter = VergeConcurrency.AtomicInt(initialValue: 0)

/**
 A handler that how receives and provides value.

 inputs value: Input -> Pipeline -> Pipeline.Result
 inputs value initially: -> Pipeline -> Output
*/
public struct Pipeline<Input, Output>: Equatable, Sendable {

  public static func == (lhs: Pipeline<Input, Output>, rhs: Pipeline<Input, Output>) -> Bool {
    lhs.identifier == rhs.identifier
  }

  public enum ContinuousResult {
    case new(Output)
    case noUpdates
  }

  // MARK: - Properties

  /*
   Properties should be `let` because to avoid mutating value with using the same identifier under the manager does not know that.
   */

  private let _makeOutput: @Sendable (Input) -> Output
  private let _makeContinousOutput: @Sendable (Input) -> ContinuousResult
  private let _dropInput: @Sendable (Input) -> Bool

  /**
   An identifier to be used from Derived to use the same instance if Pipeline is same.   
   */
  var identifier: Int = counter.getAndIncrement()

  // MARK: - Initializers
    
  @_disfavoredOverload
  public init(
    makeInitial: @escaping @Sendable (Input) -> Output,
    update: @escaping @Sendable (Input) -> ContinuousResult
  ) {
    
    self.init(makeOutput: makeInitial, dropInput: { _ in false }, makeContinuousOutput: update)
  }
  
  public init(
    map: @escaping @Sendable (Input) -> Output
  ) {
    self.init(dropInput: { _ in false }, map: map)
  }

  public init(
    dropInput: @escaping @Sendable (Input) -> Bool,
    map: @escaping @Sendable (Input) -> Output
  ) {

    self.init(
      makeOutput: map,
      dropInput: dropInput,
      makeContinuousOutput: { .new(map($0)) }
    )
  }

  /// The primitive initializer
  init(
    makeOutput: @escaping @Sendable (Input) -> Output,
    dropInput: @escaping @Sendable (Input) -> Bool,
    makeContinuousOutput: @escaping @Sendable (Input) -> ContinuousResult
  ) {

    self._makeOutput = makeOutput
    self._dropInput = dropInput
    self._makeContinousOutput = { input in
      guard !dropInput(input) else {
        return .noUpdates
      }
      return makeContinuousOutput(input)
    }
  }

  // MARK: - Functions


  // TODO: Rename `makeContinuousOutput`
  public func makeResult(_ source: Input) -> ContinuousResult {
    _makeContinousOutput(source)
  }

  // TODO: Rename `makeOutput`
  public func makeInitial(_ source: Input) -> Output {
    _makeOutput(source)
  }

  /// Tune memoization logic up.
  ///
  /// - Parameter predicate: Return true, the coming input would be dropped.
  /// - Returns:
  public func dropsInput(
    while predicate: @escaping @Sendable (Input) -> Bool
  ) -> Self {
    Self.init(
      makeOutput: _makeOutput,
      dropInput: { [_dropInput] input in
        guard !_dropInput(input) else {
          return true
        }
        guard !predicate(input) else {
          return true
        }
        return false
      },
      makeContinuousOutput: _makeContinousOutput
    )
  }

}
