//
//  Activity.swift
//  Verge
//
//  Created by muukii on 2019/07/16.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import RxRelay

public final class Emitter<Event> {
  
  private var source: Signal<Event> {
    return emitter.asSignal()
  }
  
  private let emitter: PublishRelay<Event> = .init()
  
  public init() {
    
  }
  
  public func emit(onNext: ((Event) -> Void)? = nil, onCompleted: (() -> Void)? = nil, onDisposed: (() -> Void)? = nil) -> Disposable {
    return source.emit(onNext: onNext, onCompleted: onCompleted, onDisposed: onDisposed)
  }
  
  public func asSignal() -> Signal<Event> {
    return source
  }
  
  func makeEmitter() -> Accepter<Event> {
    return .init(backingEmitter: emitter)
  }
}

public struct Accepter<Event> {
  
  private let backingEmitter: PublishRelay<Event>
  
  fileprivate init(backingEmitter: PublishRelay<Event>) {
    self.backingEmitter = backingEmitter
  }
  
  public func accept(_ event: Event) {
    backingEmitter.accept(event)
  }
}
