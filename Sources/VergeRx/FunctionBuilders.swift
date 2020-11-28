//
//  FunctionBuilders.swift
//  VergeRx
//
//  Created by muukii on 2020/01/28.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import RxSwift

@_functionBuilder public struct SubscriptionsBuilder {
  
  public static func buildBlock() -> [Disposable] {
    [Disposables.create()]
  }
  
  public static func buildBlock(_ content: Disposable) -> [Disposable] {
    [content]
  }
  
  public static func buildBlock(_ contents: Disposable...) -> [Disposable] {
    contents
  }
  
  public static func buildBlock(_ contents: [Disposable]) -> [Disposable] {
    contents
  }
  
  public static func buildBlock(_ contents: Disposable?...) -> [Disposable] {
     contents.compactMap { $0 }
   }
   
   public static func buildBlock(_ contents: [Disposable?]) -> [Disposable] {
     contents.compactMap { $0 }
   }
  
}

@available(*, deprecated)
public final class SubscriptionGroup: Disposable {
  
  private let disposable: Disposable
  
  public init(@SubscriptionsBuilder subscriptions: () -> Disposable) {
    self.disposable = Disposables.create([subscriptions()])
  }
  
  public init(@SubscriptionsBuilder subscriptions: () -> [Disposable]) {
    self.disposable = Disposables.create(subscriptions())
  }
  
  public func dispose() {
    disposable.dispose()
  }
      
}
