//
//  GetterBuilderPreFilterMethodChain.swift
//  VergeCore
//
//  Created by muukii on 2020/03/27.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

public struct GetterBuilderPreFilterMethodChain<Trait, Container: ValueContainerType, PreComparingKey> {
  
  public typealias Input = Container.Value
  
  let source: GetterBuilderMethodChain<Trait, Container>
  let preFilter: EqualityComputerBuilder<Input, PreComparingKey>
  var onTransformWillReceive: ((Input) -> Void) = { _ in }
  
  public let target: Container
  
  init(
    target: Container,
    source: GetterBuilderMethodChain<Trait, Container>,
    preFilter: EqualityComputerBuilder<Input, PreComparingKey>
  ) {
    self.target = target
    self.source = source
    self.preFilter = preFilter
  }
  
  /// Projects input object into a new form.
  public func map<Output>(_ transform: @escaping (Input) -> Output) -> GetterBuilderTransformMethodChain<Trait, Container, PreComparingKey, Output> {
    return .init(target: target, source: self, transform: transform)
  }
  
  public func `do`(onReceive: @escaping (Input) -> Void) -> Self {
    var _self = self
    let pre = onTransformWillReceive
    _self.onTransformWillReceive = { value in
      pre(value)
      onReceive(value)
    }
    return _self
  }
  
}
