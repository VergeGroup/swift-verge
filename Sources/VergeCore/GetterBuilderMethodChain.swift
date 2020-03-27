//
//  GetterBuilderMethodChain.swift
//  VergeCore
//
//  Created by muukii on 2020/03/27.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

public enum GetterBuilderTrait {
  public enum Rx {}
  public enum Combine {}
}

// MARK: - Method Chain

public struct GetterBuilderMethodChain<Trait, Container: ValueContainerType> {
  
  public typealias Input = Container.Value
  
  private let target: Container
  
  public init(target: Container) {
    self.target = target
  }
  
  /// Adding a filter to getter to map only when the input object changed.
  ///
  /// - Attention: Wheter to put `.map` before or after `.changed` should be considered according to the costs of `.map` and `.changed`.
  public func changed<PreComparingKey>(
    filter: EqualityComputerBuilder<Input, PreComparingKey>
  ) -> GetterBuilderPreFilterMethodChain<Trait, Container, PreComparingKey> {
    .init(target: target, preFilter: filter)
  }
  
  /// Adding a filter to getter to map only when the input object changed.
  ///
  /// - Attention: Wheter to put `.map` before or after `.changed` should be considered according to the costs of `.map` and `.changed`.
  public func changed<PreComparingKey>(
    keySelector: @escaping (Input) -> PreComparingKey,
    comparer: Comparer<PreComparingKey>
  )-> GetterBuilderPreFilterMethodChain<Trait, Container, PreComparingKey> {
    changed(filter: .init(keySelector: keySelector, comparer: comparer))
  }
  
  /// Adding a filter to getter to map only when the input object changed.
  ///
  /// - Attention: Wheter to put `.map` before or after `.changed` should be considered according to the costs of `.map` and `.changed`.
  public func changed(
    comparer: Comparer<Input>
  )-> GetterBuilderPreFilterMethodChain<Trait, Container, Input> {
    changed(keySelector: { $0 }, comparer: comparer)
  }
  
  /// Adding a filter to getter to map only when the input object changed.
  ///
  /// - Attention: Wheter to put `.map` before or after `.changed` should be considered according to the costs of `.map` and `.changed`.
  public func changed(
    _ equals: @escaping (Input, Input) -> Bool
  )-> GetterBuilderPreFilterMethodChain<Trait, Container, Input> {
    changed(comparer: .init(equals))
  }
  
  /// Projects input object into a new form.
  /// - Attention: No pre filter
  public func map<Output>(_ transform: @escaping (Input) -> Output) -> GetterBuilderTransformMethodChain<Trait, Container, Input, Output> {
    changed(filter: .noFilter)
      .map(transform)
  }
  
  /// No map
  /// - Attention: No pre filter
  public func noMap() -> GetterBuilderTransformMethodChain<Trait, Container, Input, Input> {
    changed(filter: .noFilter)
      .map { $0 }
  }
  
}

extension GetterBuilderMethodChain {
  
  /// Adding a filter to getter to map only when the input object changed.
  /// Filterling with Fragment
  public func changed<T>(_ fragmentSelector: @escaping (Input) -> Fragment<T>) -> GetterBuilderPreFilterMethodChain<Trait, Container, Input> {
    changed(comparer: .init(selector: {
      fragmentSelector($0).counter.rawValue
    }))
  }
  
  /// Projects input object into a new form.
  ///
  /// Filterling with Fragment and projects the wrapped value.
  public func map<Output>(_ transform: @escaping (Input) -> Fragment<Output>) -> GetterBuilderTransformMethodChain<Trait, Container, Input, Output> {
    changed(transform)
      .map { transform($0).wrappedValue }
  }
}

extension GetterBuilderMethodChain where Input : Equatable {
  
  /// Adding a filter to getter to map only when the input object changed.
  public func changed() -> GetterBuilderPreFilterMethodChain<Trait, Container, Input> {
    changed(keySelector: { $0 }, comparer: .init(==))
  }
  
  /// [Filter]
  /// Projects input object into a new form
  public func map<Output>(_ transform: @escaping (Input) -> Output) -> GetterBuilderTransformMethodChain<Trait, Container, Input, Output> {
    changed()
      .map(transform)
  }
    
  /// [Filter]
  /// No map
  public func noMap() -> GetterBuilderTransformMethodChain<Trait, Container, Input, Input> {
    changed()
      .map { $0 }
  }
  
}

public struct GetterBuilderPreFilterMethodChain<Trait, Container: ValueContainerType, PreComparingKey> {
  
  public typealias Input = Container.Value
  
  let preFilter: EqualityComputerBuilder<Input, PreComparingKey>
  
  public let target: Container
   
  init(
    target: Container,
    preFilter: EqualityComputerBuilder<Input, PreComparingKey>
  ) {
    self.target = target
    self.preFilter = preFilter
  }
  
  /// Projects input object into a new form.
  public func map<Output>(_ transform: @escaping (Input) -> Output) -> GetterBuilderTransformMethodChain<Trait, Container, PreComparingKey, Output> {
    return .init(target: target, source: self, transform: transform)
  }
    
  /// No map
  public func noMap() -> GetterBuilderTransformMethodChain<Trait, Container, PreComparingKey, Input> {
    map { $0 }
  }
}

public struct GetterBuilderTransformMethodChain<Trait, Container: ValueContainerType, PreComparingKey, Output> {
  
  public typealias Input = Container.Value
  
  public let target: Container
  
  let preFilterFragment: GetterBuilderPreFilterMethodChain<Trait, Container, PreComparingKey>
  let transform: (Input) -> Output
  
  init(
    target: Container,
    source: GetterBuilderPreFilterMethodChain<Trait, Container, PreComparingKey>,
    transform: @escaping (Input) -> Output
  ) {
    self.target = target
    self.preFilterFragment = source
    self.transform = transform
  }
  
  /// Publishes only elements that don’t match the previous element.
  /// If the cost of map is expensive, it might be better to use `.changed` before `.map`
  public func changed<PostComparingKey>(
    filter: EqualityComputerBuilder<Output, PostComparingKey>
  ) -> GetterBuilderPostFilterMethodChain<Trait, Container, PreComparingKey, Output, PostComparingKey> {
    return .init(target: target, source: self, postFilter: filter)
  }
  
  /// Publishes only elements that don’t match the previous element.
  /// If the cost of map is expensive, it might be better to use `.changed` before `.map`
  public func changed<PostComparingKey>(
    keySelector: @escaping (Output) -> PostComparingKey,
    comparer: Comparer<PostComparingKey>
  )-> GetterBuilderPostFilterMethodChain<Trait, Container, PreComparingKey, Output, PostComparingKey> {
    return changed(filter: .init(keySelector: keySelector, comparer: comparer))
  }
  
  /// Publishes only elements that don’t match the previous element.
  /// If the cost of map is expensive, it might be better to use `.changed` before `.map`
  public func changed(
    comparer: Comparer<Output>
  )-> GetterBuilderPostFilterMethodChain<Trait, Container, PreComparingKey, Output, Output> {
    return changed(filter: .init(keySelector: { $0 }, comparer: comparer))
  }
  
  /// Publishes only elements that don’t match the previous element.
  /// If the cost of map is expensive, it might be better to use pre-filter.
  public func changed(
    _ equals: @escaping (Output, Output) -> Bool
  )-> GetterBuilderPostFilterMethodChain<Trait, Container, PreComparingKey, Output, Output> {
    return changed(filter: .init(keySelector: { $0 }, comparer: .init(equals)))
  }
  
  public func makeGetterBuilder() -> GetterBuilder<Input, PreComparingKey, Output, Output> {
    .init(
      preFilter: preFilterFragment.preFilter,
      transform: transform,
      postFilter: .noFilter
    )
  }
      
}

extension GetterBuilderTransformMethodChain where Trait == GetterBuilderTrait.Combine {
  
  @available(iOS 13, macOS 10.15, *)
  public func build() -> GetterSource<Input, Output> {
    target.makeGetter(from: makeGetterBuilder())
  }
  
}

extension GetterBuilderTransformMethodChain where Output : Equatable {
  
  /// Publishes only elements that don’t match the previous element.
  public func changed()-> GetterBuilderPostFilterMethodChain<Trait, Container, PreComparingKey, Output, Output> {
    return changed(filter: .init(keySelector: { $0 }, comparer: .init(==)))
  }
}

public struct GetterBuilderPostFilterMethodChain<Trait, Container: ValueContainerType, PreComparingKey, Output, PostComparingKey> {
  
  public typealias Input = Container.Value
  
  public let target: Container
  
  let transformFragment: GetterBuilderTransformMethodChain<Trait, Container, PreComparingKey, Output>
  let postFilter: EqualityComputerBuilder<Output, PostComparingKey>
    
  init(
    target: Container,
    source: GetterBuilderTransformMethodChain<Trait, Container, PreComparingKey, Output>,
    postFilter: EqualityComputerBuilder<Output, PostComparingKey>
  ) {
    self.target = target
    self.transformFragment = source
    self.postFilter = postFilter
  }
  
  public func makeGetterBuilder() -> GetterBuilder<Input, PreComparingKey, Output, PostComparingKey> {
    .init(
      preFilter: transformFragment.preFilterFragment.preFilter,
      transform: transformFragment.transform,
      postFilter: postFilter
    )
  }
      
}

extension GetterBuilderPostFilterMethodChain where Trait == GetterBuilderTrait.Combine {
  
  @available(iOS 13, macOS 10.15, *)
  public func build() -> GetterSource<Input, Output> {    
    target.makeGetter(from: makeGetterBuilder())
  }
  
}
