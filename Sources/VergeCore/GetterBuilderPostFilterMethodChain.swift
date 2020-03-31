//
//  GetterBuilderPostFilterMethodChain.swift
//  VergeCore
//
//  Created by muukii on 2020/03/27.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

public struct GetterBuilderPostFilterMethodChain<Trait, Context, Input, PreComparingKey, Output, PostComparingKey> {
    
  public let target: Context
  
  private let transformFragment: GetterBuilderTransformMethodChain<Trait, Context, Input, PreComparingKey, Output>
  private let postFilter: EqualityComputerBuilder<Output, PostComparingKey>
  private var onPostFilterWillEmit: ((Output) -> Void) = { _ in }
  
  init(
    target: Context,
    source: GetterBuilderTransformMethodChain<Trait, Context, Input, PreComparingKey, Output>,
    postFilter: EqualityComputerBuilder<Output, PostComparingKey>
  ) {
    self.target = target
    self.transformFragment = source
    self.postFilter = postFilter
  }
  
  public func `do`(onReceive: @escaping (Output) -> Void) -> Self {
    var _self = self
    let pre = onPostFilterWillEmit
    _self.onPostFilterWillEmit = { value in
      pre(value)
      onReceive(value)
    }
    return _self
  }
  
  public func makeGetterComponents() -> GetterComponents<Input, PreComparingKey, Output, PostComparingKey> {
    
    .init(
      onPreFilterWillReceive: transformFragment.preFilterFragment.source.onPreFilterWillReceive,
      preFilter: transformFragment.preFilterFragment.preFilter,
      onTransformWillReceive: transformFragment.preFilterFragment.onTransformWillReceive,
      transform: transformFragment.transform,
      postFilter: postFilter,
      onPostFilterWillEmit: onPostFilterWillEmit
    )
    
  }
  
}

#if canImport(Combine)

extension GetterBuilderPostFilterMethodChain where Context : ValueContainerType, Trait == GetterBuilderTrait.Combine, Context.Value == Input {
  
  @available(iOS 13, macOS 10.15, *)
  public func build() -> GetterSource<Input, Output> {
    target.makeGetter(from: makeGetterComponents())
  }
  
}

#endif
