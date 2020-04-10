//
//  ValueContainerType.swift
//  VergeCore
//
//  Created by muukii on 2019/12/16.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

#if canImport(Combine)
import Combine
extension StoreType {
     
  public func getterBuilder() -> GetterBuilderMethodChain<GetterBuilderTrait.Combine, Self, State> {
    .init(target: self)
  }
      
}

extension StoreBase {
      
  @available(iOS 13, macOS 10.15, *)
  public func makeGetter<PreComparingKey, Output, PostComparingKey>(
    from components: GetterComponents<State, PreComparingKey, Output, PostComparingKey>
  ) -> GetterSource<State, Output> {
    
    let preComparer = components.preFilter.build()
    let postComparer = components.postFilter?.build()
    
    let base = statePublisher
      .handleEvents(receiveOutput: { [closure = components.onPreFilterWillReceive] value in
        closure(value.current)
      })
      .filter { value in
        !preComparer.equals(input: value.current)
    }
    .handleEvents(receiveOutput: { [closure = components.onTransformWillReceive] value in
      closure(value.current)
    })
      .map {
        components.transform($0.current)
    }
    
    let pipe: AnyPublisher<Output, Never>
    
    if let comparer = postComparer {
      pipe = base.filter { value in
        !comparer.equals(input: value)
      }
      .handleEvents(receiveOutput: { [closure = components.onPostFilterWillEmit] value in
        closure(value)
      })
        .eraseToAnyPublisher()
    } else {
      pipe = base.eraseToAnyPublisher()
    }
    
    let getterBuilder = GetterSource<State, Output>.init(input: pipe)
    
    return getterBuilder
  }
  
}
#endif
