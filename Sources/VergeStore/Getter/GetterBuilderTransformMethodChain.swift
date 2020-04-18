//
//  GetterBuilderTransformMethodChain.swift
//  VergeCore
//
//  Created by muukii on 2020/03/27.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

public struct GetterBuilderTransformMethodChain<Trait, Context, Input, Output> {
    
  public let target: Context
  
  let preFilterFragment: GetterBuilderPreFilterMethodChain<Trait, Context, Input>
  let transform: (Input) -> Output
  
  init(
    target: Context,
    source: GetterBuilderPreFilterMethodChain<Trait, Context, Input>,
    transform: @escaping (Input) -> Output
  ) {
    self.target = target
    self.preFilterFragment = source
    self.transform = transform
  }
  
  /// Publishes only elements that don’t match the previous element.
  /// If the cost of map is expensive, it might be better to use `.changed` before `.map`
  public func changed(
    filter: Comparer<Output>
  ) -> GetterBuilderPostFilterMethodChain<Trait, Context, Input, Output> {
    return .init(target: target, source: self, postFilter: filter)
  }
  
  /// Publishes only elements that don’t match the previous element.
  /// If the cost of map is expensive, it might be better to use `.changed` before `.map`
  public func changed<PostComparingKey>(
    keySelector: @escaping (Output) -> PostComparingKey,
    comparer: Comparer<PostComparingKey>
  )-> GetterBuilderPostFilterMethodChain<Trait, Context, Input, Output> {
    return changed(filter: .init(selector: keySelector, comparer: comparer))
  }
  
  /// Publishes only elements that don’t match the previous element.
  /// If the cost of map is expensive, it might be better to use `.changed` before `.map`
  public func changed(
    comparer: Comparer<Output>
  )-> GetterBuilderPostFilterMethodChain<Trait, Context, Input, Output> {
    return changed(filter: .init(selector: { $0 }, comparer: comparer))
  }
  
  /// Publishes only elements that don’t match the previous element.
  /// If the cost of map is expensive, it might be better to use pre-filter.
  public func changed(
    _ equals: @escaping (Output, Output) -> Bool
  )-> GetterBuilderPostFilterMethodChain<Trait, Context, Input, Output> {
    return changed(filter: .init(selector: { $0 }, comparer: .init(equals)))
  }
  
  public func makeGetterComponents() -> GetterComponents<Input, Output> {
    .init(
      onPreFilterWillReceive: preFilterFragment.source.onPreFilterWillReceive,
      preFilter: preFilterFragment.preFilter,
      onTransformWillReceive: preFilterFragment.onTransformWillReceive,
      transform: transform,
      postFilter: .init { _, _ in false },
      onPostFilterWillEmit: { _ in }
    )
  }
  
}

extension GetterBuilderTransformMethodChain where Output : Equatable {
  
  /// Publishes only elements that don’t match the previous element.
  public func changed()-> GetterBuilderPostFilterMethodChain<Trait, Context, Input, Output> {
    return changed(filter: .init(selector: { $0 }, comparer: .init(==)))
  }
}

#if canImport(Combine)

extension GetterBuilderTransformMethodChain where Context : StoreType, Trait == GetterBuilderTrait.Combine, Context.State == Input {
  
  @available(iOS 13, macOS 10.15, *)
  public func build() -> GetterSource<Input, Output> {
    target.asStore().makeGetter(from: makeGetterComponents())
  }
  
}

#endif
