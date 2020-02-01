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
  public func preFilter<PreComparingKey>(
    _ preFilter: EqualityComputerBuilder<Input, PreComparingKey>
  ) -> GetterBuilderPreFilterMethodChain<Input, PreComparingKey> {
    .init(preFilter: preFilter)
  }
  
  /// Adding a filter to getter to map only when the input object changed.
  /// It may be better to use post-filter if it's almost the same as operations in map and pre-filter.
  public func preFilter<PreComparingKey>(
    keySelector: KeyPath<Input, PreComparingKey>,
    comparer: Comparer<PreComparingKey>
  )-> GetterBuilderPreFilterMethodChain<Input, PreComparingKey> {
    preFilter(.init(keySelector: keySelector, comparer: comparer))
  }
  
  /// Adding a filter to getter to map only when the input object changed.
  /// It may be better to use post-filter if it's almost the same as operations in map and pre-filter.
  public func preFilter(
    comparer: Comparer<Input>
  )-> GetterBuilderPreFilterMethodChain<Input, Input> {
    preFilter(keySelector: \.self, comparer: comparer)
  }
  
  /// Projects input object into a new form.
  public func map<Output>(_ transform: @escaping (Input) -> Output) -> GetterBuilderTransformMethodChain<Input, Input, Output> {
    preFilter(.noFilter)
      .map(transform)
  }
  
  /// Projects input object into a new form.
  public func map<Output>(_ transform: KeyPath<Input, Output>) -> GetterBuilderTransformMethodChain<Input, Input, Output> {
    preFilter(.noFilter)
      .map(transform)
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
  
  /// Adding a filter to getter to emit when mapped object changed only.
  /// If the cost of map is expensive, it might be better to use pre-filter.
  public func postFilter<PostComparingKey>(
    _ postFilter: EqualityComputerBuilder<Output, PostComparingKey>
  ) -> GetterBuilderPostFilterMethodChain<Input, PreComparingkey, Output, PostComparingKey> {
    return .init(source: self, postFilter: postFilter)
  }
  
  /// Adding a filter to getter to emit when mapped object changed only.
  /// If the cost of map is expensive, it might be better to use pre-filter.
  public func postFilter<PostComparingKey>(
    keySelector: KeyPath<Output, PostComparingKey>,
    comparer: Comparer<PostComparingKey>
  )-> GetterBuilderPostFilterMethodChain<Input, PreComparingkey, Output, PostComparingKey> {
    return postFilter(.init(keySelector: keySelector, comparer: comparer))
  }
  
  /// Adding a filter to getter to emit when mapped object changed only.
  /// If the cost of map is expensive, it might be better to use pre-filter.
  public func postFilter(
    comparer: Comparer<Output>
  )-> GetterBuilderPostFilterMethodChain<Input, PreComparingkey, Output, Output> {
    return postFilter(.init(keySelector: \.self, comparer: comparer))
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


