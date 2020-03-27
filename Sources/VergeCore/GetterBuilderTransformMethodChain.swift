//
//  GetterBuilderTransformMethodChain.swift
//  VergeCore
//
//  Created by muukii on 2020/03/27.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

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
  
  public func makeGetterComponents() -> GetterComponents<Input, PreComparingKey, Output, Output> {
    .init(
      preFilter: preFilterFragment.preFilter,
      transform: transform,
      postFilter: .noFilter
    )
  }
  
}

extension GetterBuilderTransformMethodChain where Output : Equatable {
  
  /// Publishes only elements that don’t match the previous element.
  public func changed()-> GetterBuilderPostFilterMethodChain<Trait, Container, PreComparingKey, Output, Output> {
    return changed(filter: .init(keySelector: { $0 }, comparer: .init(==)))
  }
}

#if canImport(Combine)

extension GetterBuilderTransformMethodChain where Trait == GetterBuilderTrait.Combine {
  
  @available(iOS 13, macOS 10.15, *)
  public func build() -> GetterSource<Input, Output> {
    target.makeGetter(from: makeGetterComponents())
  }
  
}

#endif
