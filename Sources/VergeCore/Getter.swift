//
//  Getter.swift
//  VergeCore
//
//  Created by muukii on 2020/01/10.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

public protocol GetterType: Hashable {
  associatedtype Output
  var value: Output { get }
}

open class GetterBase<Output>: GetterType {
  
  public static func == (lhs: GetterBase<Output>, rhs: GetterBase<Output>) -> Bool {
    lhs === rhs
  }
  
  public func hash(into hasher: inout Hasher) {
    ObjectIdentifier(self).hash(into: &hasher)
  }
  
  open var value: Output {
    fatalError()
  }
  
  public init() {}
  
}

#if canImport(Combine)

import Combine

@available(iOS 13, macOS 10.15, *)
public class Getter<Output>: GetterBase<Output>, Publisher, ObservableObject {
    
  public typealias Failure = Never
  
  public static func constant<Output>(_ value: Output) -> Getter<Output> {
    .init(from: Just(value))
  }
  
  public let objectWillChange: ObservableObjectPublisher
  
  let output: CurrentValueSubject<Output, Never>
  
  public override var value: Output {
    output.value
  }
  
  private var subscriptions = Set<AnyCancellable>()
  
  /// Initialize from publisher
  ///
  /// - Attension: Please don't use operator that dispatches asynchronously.
  /// - Parameter observable:
  public convenience init<O: Publisher>(from publisher: () -> O) where O.Output == Output, O.Failure == Never {
    self.init(from: publisher())
  }
  
  /// Initialize from publisher
  ///
  /// - Attension: Please don't use operator that dispatches asynchronously.
  /// - Parameter observable:
  public init<O: Publisher>(from publisher: O) where O.Output == Output, O.Failure == Never {
    
    let pipe = publisher.buffer(size: 1, prefetch: .byRequest, whenFull: .dropOldest).makeConnectable()
    
    pipe.connect().store(in: &subscriptions)
    
    var initialValue: Output!
    
    pipe.first().sink { value in
      initialValue = value
    }
    .store(in: &subscriptions)
    
    precondition(initialValue != nil, "Don't use asynchronous operator in \(publisher), and it must emit the value immediately.")
        
    let _output = CurrentValueSubject<Output, Never>.init(initialValue)
    let _objectWillChange = ObservableObjectPublisher()
        
    pipe.sink { [weak _output, weak _objectWillChange] (value) in
      _output?.send(value)
      _objectWillChange?.send()
    }
    .store(in: &subscriptions)
    
    _output.send(initialValue)
    
    self.output = _output
    self.objectWillChange = _objectWillChange
  }
  
  public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
    output.handleEvents(receiveSubscription: { _ in
      withExtendedLifetime(self) {}
    }).receive(subscriber: subscriber)
  }
    
}

@available(iOS 13, macOS 10.15, *)
public final class GetterSource<Input, Output>: Getter<Output> {
  
  init<O: Publisher>(
    input: O
  ) where O.Output == Output, O.Failure == Never {
    
    super.init(from: input)
    
  }
  
  public func asGetter() -> Getter<Output> {
    self
  }
  
}

#endif
