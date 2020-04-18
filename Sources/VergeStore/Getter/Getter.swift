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

#if canImport(Combine)

import Combine
extension StoreType {
  
  public func getterBuilder() -> GetterBuilderMethodChain<GetterBuilderTrait.Combine, Self, State> {
    .init(target: self)
  }
  
}

extension Store {
  
  @available(iOS 13, macOS 10.15, *)
  fileprivate func makeStream<PreComparingKey, Output, PostComparingKey>(
    from components: GetterComponents<State, PreComparingKey, Output, PostComparingKey>
  ) -> AnyPublisher<Changes<Output>, Never> {
    
    let postComparer = components.postFilter
     
    let base = changesPublisher
      .handleEvents(receiveOutput: { [closure = components.onPreFilterWillReceive] value in
        closure(value.current)
      })
      .filter({ value in
        value.hasChanges(compare: components.preFilter.isEqual)
      })
      .handleEvents(receiveOutput: { [closure = components.onTransformWillReceive] value in
        closure(value.current)
      })
      .map({
        components.transform($0.current)
      })
      .scan(Optional<Changes<Output>>.none, { (pre, element) in
        guard pre != nil else {
          return .init(old: nil, new: element)
        }
        var _next = pre
        _next!.update(with: element)
        return _next!
      })
      .map({ $0! })
    
    let pipe: AnyPublisher<Changes<Output>, Never>
    
    if let comparer = postComparer {
      pipe = base
        .filter({ value in
          value.hasChanges(compare: comparer.isEqual)
        })
        .handleEvents(receiveOutput: { [closure = components.onPostFilterWillEmit] value in
          closure(value.current)
        })
        .eraseToAnyPublisher()
    } else {
      pipe = base.eraseToAnyPublisher()
    }
    
    return pipe
    
  }
  
  @available(iOS 13, macOS 10.15, *)
  public func makeGetter<PreComparingKey, Output, PostComparingKey>(
    from components: GetterComponents<State, PreComparingKey, Output, PostComparingKey>
  ) -> GetterSource<State, Output> {
    
    let pipe = makeStream(from: components).map(\.current)
    let getterBuilder = GetterSource<State, Output>.init(input: pipe)
    
    return getterBuilder
  }
  
  @available(iOS 13, macOS 10.15, *)
  public func makeChangesGetter<PreComparingKey, Output, PostComparingKey>(
    from components: GetterComponents<State, PreComparingKey, Output, PostComparingKey>
  ) -> GetterSource<State, Changes<Output>> {
    
    let pipe = makeStream(from: components)
    let getterBuilder = GetterSource<State, Changes<Output>>.init(input: pipe)
    
    return getterBuilder
  }
  
}
#endif
