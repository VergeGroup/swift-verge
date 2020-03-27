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
