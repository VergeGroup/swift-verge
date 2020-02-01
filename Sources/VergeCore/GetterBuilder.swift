//
//  GetterBuilder.swift
//  VergeCore
//
//  Created by muukii on 2020/01/14.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

public struct GetterBuilder<Input, PreComparingKey, Output, PostComparingKey> {
  
  public let preFilter: EqualityComputerBuilder<Input, PreComparingKey>
  public let transform: (Input) -> Output
  public let postFilter: EqualityComputerBuilder<Output, PostComparingKey>?
    
  public init(
    preFilter: EqualityComputerBuilder<Input, PreComparingKey>,
    transform: @escaping (Input) -> Output,
    postFilter: EqualityComputerBuilder<Output, PostComparingKey>
  ) {
    
    self.preFilter = preFilter
    self.transform = transform
    self.postFilter = postFilter
    
  }
  
}

extension GetterBuilder {
  
  public static func make(
    preFilter: EqualityComputerBuilder<Input, PreComparingKey>,
    transform: @escaping (Input) -> Output
  ) -> GetterBuilder<Input, PreComparingKey, Output, Output> {
    
    return .init(
      preFilter: preFilter,
      transform: transform,
      postFilter: .noFilter
    )
    
  }
  
  public static func from(_ fragment: GetterBuilderTransformMethodChain<Input, PreComparingKey, Output>) -> GetterBuilder<Input, PreComparingKey, Output, Output> {
    
    let f = fragment
    
    return .init(
      preFilter: f.preFilterFragment.preFilter,
      transform: f.transform,
      postFilter: .noFilter
    )
    
  }
  
  public static func from(_ fragment: GetterBuilderPostFilterMethodChain<Input, PreComparingKey, Output, PostComparingKey>) -> GetterBuilder<Input, PreComparingKey, Output, PostComparingKey> {
    
    let f = fragment
    
    return .init(
      preFilter: f.transformFragment.preFilterFragment.preFilter,
      transform: f.transformFragment.transform,
      postFilter: f.postFilter
    )
    
  }
  
}

// MARK: - Method Chain

public struct GetterBuilderMethodChain<Input> {
  
  public init() {}
  
  /// Adding a filter to getter to map only when the input object changed.
  /// It may be better to use post-filter if it's almost the same as operations in map and pre-filter.
  public func changed<PreComparingKey>(
    filter: EqualityComputerBuilder<Input, PreComparingKey>
  ) -> GetterBuilderPreFilterMethodChain<Input, PreComparingKey> {
    .init(preFilter: filter)
  }
  
  /// Adding a filter to getter to map only when the input object changed.
  /// It may be better to use post-filter if it's almost the same as operations in map and pre-filter.
  public func changed<PreComparingKey>(
    keySelector: KeyPath<Input, PreComparingKey>,
    comparer: Comparer<PreComparingKey>
  )-> GetterBuilderPreFilterMethodChain<Input, PreComparingKey> {
    changed(filter: .init(keySelector: keySelector, comparer: comparer))
  }
  
  /// Adding a filter to getter to map only when the input object changed.
  /// It may be better to use post-filter if it's almost the same as operations in map and pre-filter.
  public func changed(
    comparer: Comparer<Input>
  )-> GetterBuilderPreFilterMethodChain<Input, Input> {
    changed(keySelector: \.self, comparer: comparer)
  }
  
  /// Projects input object into a new form.
  public func map<Output>(_ transform: @escaping (Input) -> Output) -> GetterBuilderTransformMethodChain<Input, Input, Output> {
    changed(filter: .noFilter)
      .map(transform)
  }
  
  /// Projects input object into a new form.
  public func map<Output>(_ transform: KeyPath<Input, Output>) -> GetterBuilderTransformMethodChain<Input, Input, Output> {
    changed(filter: .noFilter)
      .map(transform)
  }
  
  /// No map
  public func noMap() -> GetterBuilderTransformMethodChain<Input, Input, Input> {
    changed(filter: .noFilter)
      .map { $0 }
  }
  
}

extension GetterBuilderMethodChain where Input : Equatable {
  
  /// Adding a filter to getter to map only when the input object changed.
  public func changed()-> GetterBuilderPreFilterMethodChain<Input, Input> {
    changed(keySelector: \.self, comparer: .init(==))
  }
  
  /// [Filter]
  /// Projects input object into a new form
  public func map<Output>(_ transform: @escaping (Input) -> Output) -> GetterBuilderTransformMethodChain<Input, Input, Output> {
    changed()
      .map(transform)
  }
  
  /// [Filter]
  /// Projects input object into a new form.
  public func map<Output>(_ transform: KeyPath<Input, Output>) -> GetterBuilderTransformMethodChain<Input, Input, Output> {
    changed()
      .map(transform)
  }
  
  /// [Filter]
  /// No map
  public func noMap() -> GetterBuilderTransformMethodChain<Input, Input, Input> {
    changed()
      .map { $0 }
  }
    
}

public struct GetterBuilderPreFilterMethodChain<Input, PreComparingKey> {
  
  let preFilter: EqualityComputerBuilder<Input, PreComparingKey>
  
  init(
    preFilter: EqualityComputerBuilder<Input, PreComparingKey>
  ) {
    self.preFilter = preFilter
  }
  
  /// Projects input object into a new form.
  public func map<Output>(_ transform: @escaping (Input) -> Output) -> GetterBuilderTransformMethodChain<Input, PreComparingKey, Output> {
    return .init(source: self, transform: transform)
  }
  
  /// Projects input object into a new form.
  public func map<Output>(_ transform: KeyPath<Input, Output>) -> GetterBuilderTransformMethodChain<Input, PreComparingKey, Output> {
    return .init(source: self, transform: { $0[keyPath: transform] })
  }
  
  /// No map
  public func noMap() -> GetterBuilderTransformMethodChain<Input, PreComparingKey, Input> {
    map { $0 }
  }
}

public struct GetterBuilderTransformMethodChain<Input, PreComparingkey, Output> {
  
  let preFilterFragment: GetterBuilderPreFilterMethodChain<Input, PreComparingkey>
  let transform: (Input) -> Output
  
  init(
    source: GetterBuilderPreFilterMethodChain<Input, PreComparingkey>,
    transform: @escaping (Input) -> Output
  ) {
    self.preFilterFragment = source
    self.transform = transform
  }
  
  /// Publishes only elements that don’t match the previous element.
  /// If the cost of map is expensive, it might be better to use pre-filter.
  public func changed<PostComparingKey>(
    filter: EqualityComputerBuilder<Output, PostComparingKey>
  ) -> GetterBuilderPostFilterMethodChain<Input, PreComparingkey, Output, PostComparingKey> {
    return .init(source: self, postFilter: filter)
  }
  
  /// Publishes only elements that don’t match the previous element.
  /// If the cost of map is expensive, it might be better to use pre-filter.
  public func changed<PostComparingKey>(
    keySelector: KeyPath<Output, PostComparingKey>,
    comparer: Comparer<PostComparingKey>
  )-> GetterBuilderPostFilterMethodChain<Input, PreComparingkey, Output, PostComparingKey> {
    return changed(filter: .init(keySelector: keySelector, comparer: comparer))
  }
  
  /// Publishes only elements that don’t match the previous element.
  /// If the cost of map is expensive, it might be better to use pre-filter.
  public func changed(
    comparer: Comparer<Output>
  )-> GetterBuilderPostFilterMethodChain<Input, PreComparingkey, Output, Output> {
    return changed(filter: .init(keySelector: \.self, comparer: comparer))
  }
  
  /// Publishes only elements that don’t match the previous element.
  /// If the cost of map is expensive, it might be better to use pre-filter.
  public func changed(
    _ equals: @escaping (Output, Output) -> Bool
  )-> GetterBuilderPostFilterMethodChain<Input, PreComparingkey, Output, Output> {
    return changed(filter: .init(keySelector: \.self, comparer: .init(equals)))
  }
  
}

extension GetterBuilderTransformMethodChain where Output : Equatable {
  
  /// Publishes only elements that don’t match the previous element.
  public func changed()-> GetterBuilderPostFilterMethodChain<Input, PreComparingkey, Output, Output> {
    return changed(filter: .init(keySelector: \.self, comparer: .init(==)))
  }
}

public struct GetterBuilderPostFilterMethodChain<Input, PreComparingkey, Output, PostComparingKey> {
  
  let transformFragment: GetterBuilderTransformMethodChain<Input, PreComparingkey, Output>
  let postFilter: EqualityComputerBuilder<Output, PostComparingKey>
  
  init(
    source: GetterBuilderTransformMethodChain<Input, PreComparingkey, Output>,
    postFilter: EqualityComputerBuilder<Output, PostComparingKey>
  ) {
    self.transformFragment = source
    self.postFilter = postFilter
  }
  
}


