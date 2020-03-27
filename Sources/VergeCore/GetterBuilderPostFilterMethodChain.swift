//
//  GetterBuilderPostFilterMethodChain.swift
//  VergeCore
//
//  Created by muukii on 2020/03/27.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

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
  
  public func makeGetterComponents() -> GetterComponents<Input, PreComparingKey, Output, PostComparingKey> {
    .init(
      preFilter: transformFragment.preFilterFragment.preFilter,
      transform: transformFragment.transform,
      postFilter: postFilter
    )
  }
  
}

#if canImport(Combine)

extension GetterBuilderPostFilterMethodChain where Trait == GetterBuilderTrait.Combine {
  
  @available(iOS 13, macOS 10.15, *)
  public func build() -> GetterSource<Input, Output> {
    target.makeGetter(from: makeGetterComponents())
  }
  
}

#endif
