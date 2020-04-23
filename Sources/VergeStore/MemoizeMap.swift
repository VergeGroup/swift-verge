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

import Foundation

// TODO: Get a good name
// StatePipeline
public struct MemoizeMap<Input, Output> {
  
  public enum Result {
    case updated(Output)
    case noChanages
  }
    
  private let _makeInitial: (Input) -> Output
  private var _dropInput: (Input) -> Bool
  private var _update: (Input) -> Result
    
  public init(
    makeInitial: @escaping (Input) -> Output,
    update: @escaping (Input) -> Result
  ) {
    
    self.init(makeInitial: makeInitial, dropInput: { _ in false }, update: update)
  }
  
  public init(
    map: @escaping (Input) -> Output
  ) {
    self.init(dropInput: { _ in false }, map: map)
  }
    
  private init(
    makeInitial: @escaping (Input) -> Output,
    dropInput: @escaping (Input) -> Bool,
    update: @escaping (Input) -> Result
  ) {
    
    self._makeInitial = makeInitial
    self._dropInput = dropInput
    self._update = { input in
      guard !dropInput(input) else {
        return .noChanages
      }
      return update(input)
    }
  }
    
  public init(
    dropInput: @escaping (Input) -> Bool,
    map: @escaping (Input) -> Output
  ) {
    
    self.init(
      makeInitial: map,
      dropInput: dropInput,
      update: { .updated(map($0)) }
    )
  }
  
  func makeResult(_ source: Input) -> Result {
    _update(source)
  }
  
  func makeInitial(_ source: Input) -> Output {
    _makeInitial(source)
  }
  
  public func dropsInput(
    while predicate: @escaping (Input) -> Bool
  ) -> Self {
    Self.init(
      makeInitial: _makeInitial,
      dropInput: { [_dropInput] input in
        guard !_dropInput(input) else {
          return true
        }
        guard !predicate(input) else {
          return true
        }
        return false
      },
      update: _update
    )
  }
   
}

extension MemoizeMap where Input : ChangesType, Input.Value : Equatable {
    
  /// Using implicit drop-input with Equatable
  /// - Parameter map:
  public init(
    map: @escaping (Input) -> Output
  ) {
    
    self.init(
      makeInitial: map,
      dropInput: { $0.asChanges().noChanges(\.root) },
      update: { .updated(map($0)) }
    )
  }
  
  /// Using implicit drop-input with Equatable
  public static func map(_ map: @escaping (Input) -> Output) -> Self {
    .init(map: map)
  }
  
}

extension MemoizeMap where Input : ChangesType {
  
}

extension MemoizeMap {
  
  public static func map(_ map: @escaping (Input) -> Output) -> Self {
    .init(dropInput: { _ in false }, map: map)
  }
}

