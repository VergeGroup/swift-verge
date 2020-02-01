//
//  ValueContainerType.swift
//  VergeCore
//
//  Created by muukii on 2019/12/16.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public protocol ValueContainerType: AnyObject {
  associatedtype Value
  
  var wrappedValue: Value { get }
  
  func lock()
  func unlock()
  
  #if canImport(Combine)
     
  @available(iOS 13, macOS 10.15, *)
  func makeGetter<PreComparingKey, Output, PostComparingKey>(
    from builder: GetterBuilder<Value, PreComparingKey, Output, PostComparingKey>
  ) -> GetterSource<Value, Output>
  
  #endif
}

#if canImport(Combine)
import Combine
extension ValueContainerType {
  
  /// Dummy for Xcode's code completion
  @available(*, deprecated, message: "Dummy method")
  @available(iOS 13, macOS 10.15, *)
  public func makeGetter(_ make: (GetterBuilderMethodChain<Value>) -> Never) -> Never {
    fatalError()
  }
  
  /// Dummy for Xcode's code completion
  @available(*, deprecated, message: "You need to call `.map` more.")
  @available(iOS 13, macOS 10.15, *)
  public func makeGetter<PreComparingKey>(_ make: (GetterBuilderMethodChain<Value>) -> GetterBuilderPreFilterMethodChain<Value, PreComparingKey>) -> Never {
    fatalError()
  }
  
  /// Value -> [PreFilter -> Transform] -> Value
  @available(iOS 13, macOS 10.15, *)
  public func makeGetter<PreComparingKey, Output>(_ make: (GetterBuilderMethodChain<Value>) -> GetterBuilderTransformMethodChain<Value, PreComparingKey, Output>) -> GetterSource<Value, Output> {
    return makeGetter(from: .from(make(.init())))
  }
  
  /// Value -> [PreFilter -> Transform -> PostFilter] -> Value
  @available(iOS 13, macOS 10.15, *)
  public func makeGetter<PreComparingKey, Output, PostComparingKey>(_ make: (GetterBuilderMethodChain<Value>) -> GetterBuilderPostFilterMethodChain<Value, PreComparingKey, Output, PostComparingKey>) -> GetterSource<Value, Output> {
    return makeGetter(from: .from(make(.init())))
  }
      
}
#endif

extension Storage: ValueContainerType {
  
  public func lock() {
    _lock.lock()
  }

  public func unlock() {
    _lock.unlock()
  }
  
  #if canImport(Combine)
  
  @available(iOS 13, macOS 10.15, *)
  
  public func makeGetter<PreComparingKey, Output, PostComparingKey>(
    from builder: GetterBuilder<Value, PreComparingKey, Output, PostComparingKey>
  ) -> GetterSource<Value, Output> {
    
    let preComparer = builder.preFilter.build()
    let postComparer = builder.postFilter?.build()
    
    let base = publisher
      .filter { value in
        !preComparer.equals(input: value)
    }
    .map(builder.transform)
    
    let pipe: AnyPublisher<Output, Never>
    
    if let comparer = postComparer {
      pipe = base.filter { value in
        !comparer.equals(input: value)
      }
      .eraseToAnyPublisher()
    } else {
      pipe = base.eraseToAnyPublisher()
    }
       
    let makeGetter = GetterSource<Value, Output>.init(input: pipe)
    
    return makeGetter
  }
   
  #endif
}
