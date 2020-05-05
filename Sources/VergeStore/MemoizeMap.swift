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

/// A pipeline object to make derived data from the source store.
/// It supports Memoization
///
/// - TODO:
///   - make identifier to cache Derived<T>
public struct MemoizeMap<Input, Output> {
       
  public enum Result {
    case updated(Output)
    case noChanages
  }
    
  private let _makeInitial: (Input) -> Output
  private var _dropInput: (Input) -> Bool
  private var _update: (Input) -> Result
  
  private(set) var identifier: String = UUID().uuidString
    
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
  
  public func makeResult(_ source: Input) -> Result {
    _update(source)
  }
  
  public func makeInitial(_ source: Input) -> Output {
    _makeInitial(source)
  }
    
  /// Tune memoization logic up.
  ///
  /// - Parameter predicate: Return true, the coming input would be dropped.
  /// - Returns:
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

extension MemoizeMap where Input : ChangesType {
  
  /// Projects a value of Fragment structure from Input with memoized by the version of Fragment.
  ///
  /// - Complexity: ✅ Active Memoization with Fragment's version
  /// - Parameter map:
  /// - Returns:
  public static func map(_ map: @escaping (Changes<Input.Value>.Composing) -> Fragment<Output>) -> MemoizeMap<Input, Output> {
            
    return .init(
      makeInitial: {
        
        map($0.asChanges().makeComposing()).wrappedValue
        
    }, update: { changes in
      
      // avoid copying body state
      // returns only version
      let versionUpdated = changes.asChanges().hasChanges({ map($0).version }, ==)
      
      guard versionUpdated else {
        return .noChanages
      }
      
      return .updated(map(changes.asChanges().makeComposing()).wrappedValue)
    })
  }
  
  /// Projects a value of Fragment structure from Input with memoized by the version of Fragment.
  ///
  /// - Complexity: ✅ Active Memoization with Fragment's version
  /// - Parameter map:
  /// - Returns:
  public static func map(_ keyPath: KeyPath<Changes<Input.Value>.Composing, Fragment<Output>>) -> MemoizeMap<Input, Output> {
        
    var instance = MemoizeMap.map({ $0[keyPath: keyPath] })
    
    Static.modify { cache in
      let keyPathID = KeyPathIdentifierStore.getLocalIdentifier(keyPath)
      if let id = cache[keyPathID] {
        instance.identifier = id
      } else {
        cache[keyPathID] = instance.identifier
      }
    }
    
    return instance
  }
  
}

extension MemoizeMap where Input : ChangesType, Input.Value : Equatable {
  
  /// Projects a specified shape from Input.
  ///
  /// - Complexity: ✅ Using implicit drop-input with Equatable
  /// - Parameter map:
  public init(
    map: @escaping (Changes<Input.Value>.Composing) -> Output
  ) {
    
    self.init(
      makeInitial: { map($0.asChanges().makeComposing()) },
      dropInput: { $0.asChanges().noChanges(\.root) },
      update: { .updated(map($0.asChanges().makeComposing())) }
    )
  }
  
  /// Projects a specified shape from Input.
  ///
  /// - Complexity: ✅ Using implicit drop-input with Equatable
  /// - Parameter map:
  public static func map(_ map: @escaping (Changes<Input.Value>.Composing) -> Output) -> Self {
    .init(map: map)
  }
  
  /// Projects a specified shape from Input.
  ///
  /// - Complexity: ✅ Using implicit drop-input with Equatable
  /// - Parameter map:
  public static func map(_ keyPath: KeyPath<Changes<Input.Value>.Composing, Output>) -> Self {
    var instance = MemoizeMap.map({ $0[keyPath: keyPath] })
        
    Static.modify { cache in
      let keyPathID = KeyPathIdentifierStore.getLocalIdentifier(keyPath)
      if let id = cache[keyPathID] {
        instance.identifier = id
      } else {
        cache[keyPathID] = instance.identifier
      }
    }
    
    return instance
  }
}


extension MemoizeMap {
    
  /// Projects a specified shape from Input.
  ///
  /// - Complexity: ⚠️ No memoization, additionally you need to call `dropsInput` to get memoization.
  ///
  /// - Parameter map:
  /// - Returns:
  public static func map(_ map: @escaping (Input) -> Output) -> Self {
    .init(dropInput: { _ in false }, map: map)
  }
  
  /// Projects a specified shape from Input.
  ///
  /// - Complexity: ⚠️ No memoization, additionally you need to call `dropsInput` to get memoization.
  ///
  /// - Parameter map:
  /// - Returns:
  public static func map(_ keyPath: KeyPath<Input, Output>) -> Self {
            
    var instance = map({ $0[keyPath: keyPath] })
        
    Static.modify { cache in
      let keyPathID = KeyPathIdentifierStore.getLocalIdentifier(keyPath)
      if let id = cache[keyPathID] {
        instance.identifier = id
      } else {
        cache[keyPathID] = instance.identifier
      }
    }
            
    return instance
  }
  
}

enum KeyPathIdentifierStore {
  
  static var cache: [AnyKeyPath : String] = [:]
  
  static func getLocalIdentifier(_ keyPath: AnyKeyPath) -> String {
    if let id = cache[keyPath] {
      return id
    } else {
      let newID = UUID().uuidString
      cache[keyPath] = "KeyPath:\(newID)"
      return newID
    }
  }
  
}

fileprivate enum Static {
  private static var cache: VergeConcurrency.Atomic<[Int : [String : String]]> = .init([:])
  
  static func modify<Result>(on line: Int = #line, modify: (inout [String : String]) -> Result) -> Result {
    cache.modify { cache in
      var target = cache[line, default: [:]]
      let r = modify(&target)
      cache[line] = target
      return r
    }
  }
     
}
