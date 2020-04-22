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
public struct FilterMap<Input, Output> {
  
  public enum Result {
    case updated(Output)
    case noChanages
  }
  
  private let _makeInitial: (Input) -> Output
  private var _update: (Input) -> Result
  
  public init(
    makeInitial: @escaping (Input) -> Output,
    update: @escaping (Input) -> Result
  ) {
    self._makeInitial = makeInitial
    self._update = update
  }
    
  public init(
    preFilter: @escaping (Input) -> Bool,
    map: @escaping (Input) -> Output
  ) {
    
    self.init(
      makeInitial: map,
      update: { source in
        guard !preFilter(source) else { return .noChanages }
        let result = map(source)
        return .updated(result)
    })
    
  }
  
  func makeResult(_ source: Input) -> Result {
    _update(source)
  }
  
  func makeInitial(_ source: Input) -> Output {
    _makeInitial(source)
  }
  
  public func combinedPreFilter(
    _ filter: @escaping (Input) -> Bool
  ) -> Self {
    
    var _self = self
    _self._update = { [_update] source in
      guard !filter(source) else { return .noChanages }
      return _update(source)
    }
    return _self
  }
  
  public func combinedPostFilter(
    _ filter: @escaping (Output) -> Bool
  ) -> Self {
    
    var _self = self
    _self._update = { [_update] source in
      let result = _update(source)
      switch result {
      case .noChanages:
        return .noChanages
      case .updated(let result):
        if filter(result) {
          return .noChanages
        }
        return .updated(result)
      }
    }
    return _self
  }
  
  public func combined<NewDistination>(
    _ other: FilterMap<Output, NewDistination>
  ) -> FilterMap<Input, NewDistination> {
    
    FilterMap<Input, NewDistination>.init(
      makeInitial: { [_makeInitial] source in
        other.makeInitial(_makeInitial(source))
    },
      update: { [_update] source in
        switch _update(source) {
        case .noChanages: return .noChanages
        case .updated(let t):
          switch other.makeResult(t) {
          case .noChanages: return .noChanages
          case .updated(let d):
            return .updated(d)
          }
        }
    })
    
  }
  
}

extension FilterMap where Input : ChangesType {
  public init(
    preFilter: Comparer<Input.Value>,
    map: @escaping (Input) -> Output
  ) {
    self.init(
      preFilter: {
        $0.hasChanges(compare: preFilter.equals)
    },
      map: map
    )
  }
}

extension FilterMap {
  
  public static func map(_ map: @escaping (Input) -> Output) -> Self {
    .init(preFilter: { _ in false }, map: map)
  }
}
