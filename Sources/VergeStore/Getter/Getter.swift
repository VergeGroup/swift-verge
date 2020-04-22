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

open class GetterBase<Output>: GetterType, CustomReflectable {
    
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
  
  public var customMirror: Mirror {
    Mirror.init(self, children: ["value" : value], displayStyle: .struct, ancestorRepresentation: .generated)
  }
  
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
  
  fileprivate init<O: Publisher>(from publisher: O, initialValue: O.Output) where O.Output == Output, O.Failure == Never {
    
    let pipe = publisher.buffer(size: 1, prefetch: .byRequest, whenFull: .dropOldest).makeConnectable()
    
    pipe.connect().store(in: &subscriptions)
    
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
  public convenience init<O: Publisher>(from publisher: O) where O.Output == Output, O.Failure == Never {
    
    let pipe = publisher.buffer(size: 1, prefetch: .byRequest, whenFull: .dropOldest).makeConnectable()
    
    var _subs = Set<AnyCancellable>()
    
    pipe.connect().store(in: &_subs)
    
    var initialValue: Output!
    
    pipe.first().sink { value in
      initialValue = value
    }
    .store(in: &_subs)
    
    precondition(initialValue != nil, "Don't use asynchronous operator in \(publisher), and it must emit the value immediately.")
  
    self.init(from: pipe, initialValue: initialValue)
    
    subscriptions.formUnion(_subs)
  }
  
  public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
    output.handleEvents(receiveSubscription: { _ in
      withExtendedLifetime(self) {}
    }).receive(subscriber: subscriber)
  }
    
}

@available(iOS 13, macOS 10.15, *)
public final class GetterSource<Input, Output>: Getter<Output> {
  
  public func asGetter() -> Getter<Output> {
    self
  }
  
}

#endif

#if canImport(Combine)

import Combine
extension StoreType {
  
  public func getterBuilder() -> GetterBuilderMethodChain<GetterBuilderTrait.Combine, Self, State> {
    .init(target: self)
  }
  
}

extension Store {
  
  @available(iOS 13, macOS 10.15, *)
  fileprivate func makeStream<Output>(
    from components: GetterComponents<State, Output>
  ) -> (AnyPublisher<Changes<Output>, Never>, Changes<Output>) {
    
    let initialValue = Changes<Output>.init(old: nil, new: components.transform(changes.current))
        
    let base = changesPublisher
      .dropFirst()
      .handleEvents(receiveOutput: { [closure = components.onPreFilterWillReceive] value in
        closure(value.current)
      })
      .filter({ value in
        !components.preFilter(value)
      })
      .handleEvents(receiveOutput: { [closure = components.onTransformWillReceive] value in
        closure(value.current)
      })
      .map({
        components.transform($0.current)
      })
      .scan(initialValue, { (pre, element) in
        var _next = pre
        _next.update(with: element)
        return _next
      })
      .filter({ value in
        !components.postFilter(value)
      })
      .handleEvents(receiveOutput: { [closure = components.onPostFilterWillEmit] value in
        closure(value.current)
      })
      .eraseToAnyPublisher()
    
    return (base, initialValue)
    
  }
  
  @available(iOS 13, macOS 10.15, *)
  public func makeGetter<Output>(
    from components: GetterComponents<State, Output>
  ) -> GetterSource<State, Output> {
    
    let (stream, initialValue) = makeStream(from: components)
    let getterBuilder = GetterSource<State, Output>.init(from: stream.map(\.current), initialValue: initialValue.current)
    
    return getterBuilder
  }
  
  @available(iOS 13, macOS 10.15, *)
  public func makeChangesGetter<Output>(
    from components: GetterComponents<State, Output>
  ) -> GetterSource<State, Changes<Output>> {
    
    let (stream, initialValue) = makeStream(from: components)
    let getterBuilder = GetterSource<State, Changes<Output>>.init(from: stream, initialValue: initialValue)
    
    return getterBuilder
  }
  
}

#endif
