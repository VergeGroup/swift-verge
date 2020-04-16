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

public struct GetterBuilderMethodChain<Trait, Context, Input> {
    
  private let target: Context
  var onPreFilterWillReceive: ((Input) -> Void) = { _ in }
  
  public init(target: Context) {
    self.target = target
  }
  
  public func `do`(onReceive: @escaping (Input) -> Void) -> Self {
    var _self = self
    let pre = onPreFilterWillReceive
    _self.onPreFilterWillReceive = { value in
      pre(value)
      onReceive(value)
    }
    return _self
  }
  
  /// Adding a filter to getter to map only when the input object changed.
  ///
  /// - Attention: Wheter to put `.map` before or after `.changed` should be considered according to the costs of `.map` and `.changed`.
  @inline(__always)
  public func changed<PreComparingKey>(
    filter: EqualityComputerBuilder<Input, PreComparingKey>
  ) -> GetterBuilderPreFilterMethodChain<Trait, Context, Input, PreComparingKey> {
    .init(target: target, source: self, preFilter: filter)
  }
  
  /// Adding a filter to getter to map only when the input object changed.
  ///
  /// - Attention: Wheter to put `.map` before or after `.changed` should be considered according to the costs of `.map` and `.changed`.
  public func changed<PreComparingKey>(
    keySelector: @escaping (Input) -> PreComparingKey,
    comparer: Comparer<PreComparingKey>
  )-> GetterBuilderPreFilterMethodChain<Trait, Context, Input, PreComparingKey> {
    changed(filter: .init(keySelector: keySelector, comparer: comparer))
  }
  
  /// Adding a filter to getter to map only when the input object changed.
  ///
  /// - Attention: Wheter to put `.map` before or after `.changed` should be considered according to the costs of `.map` and `.changed`.
  public func changed(
    comparer: Comparer<Input>
  )-> GetterBuilderPreFilterMethodChain<Trait, Context, Input, Input> {
    changed(keySelector: { $0 }, comparer: comparer)
  }
  
  /// Adding a filter to getter to map only when the input object changed.
  ///
  /// - Attention: Wheter to put `.map` before or after `.changed` should be considered according to the costs of `.map` and `.changed`.
  public func changed(
    _ equals: @escaping (Input, Input) -> Bool
  )-> GetterBuilderPreFilterMethodChain<Trait, Context, Input, Input> {
    changed(comparer: .init(equals))
  }
  
  /// Projects input object into a new form.
  ///
  /// - Attention: No pre filter. It may cause performance issue. Consider using .changed() before.
  public func mapWithoutPreFilter<Output>(_ transform: @escaping (Input) -> Output) -> GetterBuilderTransformMethodChain<Trait, Context, Input, Input, Output> {
    changed(filter: .noFilter)
      .map(transform)
  }
    
}

extension GetterBuilderMethodChain {
  
  /// Compare using Fragment's counter
  ///
  /// Adding a filter to getter to map only when the input object changed.
  public func changed<T>(_ fragmentSelector: @escaping (Input) -> Fragment<T>) -> GetterBuilderPreFilterMethodChain<Trait, Context, Input, Input> {
    changed(comparer: .init(selector: {
      fragmentSelector($0).counter.rawValue
    }))
  }
  
  /// Projects input object into a new form.
  ///
  /// Filterling with Fragment and projects the wrapped value.
  public func map<Output>(_ transform: @escaping (Input) -> Fragment<Output>) -> GetterBuilderTransformMethodChain<Trait, Context, Input, Input, Output> {
    changed(transform)
      .map { transform($0).wrappedValue }
  }
}

extension GetterBuilderMethodChain where Input : Equatable {
  
  /// Compare using Equatable
  ///
  /// Adding a filter to getter to map only when the input object changed.
  public func changed() -> GetterBuilderPreFilterMethodChain<Trait, Context, Input, Input> {
    changed(keySelector: { $0 }, comparer: .init(==))
  }
  
  /// [Filter]
  /// Projects input object into a new form
  public func map<Output>(_ transform: @escaping (Input) -> Output) -> GetterBuilderTransformMethodChain<Trait, Context, Input, Input, Output> {
    changed()
      .map(transform)
  }
      
}
