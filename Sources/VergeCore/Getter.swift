//
//  Getter.swift
//  VergeCore
//
//  Created by muukii on 2020/01/10.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

open class GetterBase<Output> {
  
  open var value: Output {
    fatalError()
  }
  
  public init() {}
  
}

#if canImport(Combine)

import Combine

@available(iOS 13, macOS 10.15, *)
public class Getter<Output>: GetterBase<Output>, Publisher {
  
  public typealias Failure = Never
  
  let output: CurrentValueSubject<Output, Never>
  
  public override var value: Output {
    output.value
  }
  
  private var subscriptions = Set<AnyCancellable>()
  
  public convenience init<O: Publisher>(from publisher: () -> O) where O.Output == Output, O.Failure == Never {
    self.init(from: publisher())
  }
  
  public init<O: Publisher>(from publisher: O) where O.Output == Output, O.Failure == Never {
    
    let pipe = publisher.buffer(size: 1, prefetch: .byRequest, whenFull: .dropOldest).makeConnectable()
    
    pipe.connect().store(in: &subscriptions)
    
    var initialValue: Output!
    
    publisher.sink { value in
      initialValue = value
    }
    .store(in: &subscriptions)
        
    let _output = CurrentValueSubject<Output, Never>.init(initialValue)
        
    publisher.sink { (value) in
      _output.send(value)
    }
    .store(in: &subscriptions)
    
    self.output = _output
  }
  
  public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {

    output.receive(subscriber: subscriber)
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

fileprivate var _willChangeAssociated: Void?
fileprivate var _didChangeAssociated: Void?

@available(iOS 13.0, macOS 10.15, *)
extension Storage: ObservableObject {
  
  public var objectWillChange: ObservableObjectPublisher {
    if let associated = objc_getAssociatedObject(self, &_willChangeAssociated) as? ObservableObjectPublisher {
      return associated
    } else {
      let associated = ObservableObjectPublisher()
      objc_setAssociatedObject(self, &_willChangeAssociated, associated, .OBJC_ASSOCIATION_RETAIN)
      
      addWillUpdate {
        if Thread.isMainThread {
          associated.send()
        } else {
          DispatchQueue.main.async {
            associated.send()
          }
        }
      }
      
      return associated
    }
  }
  
  public var publisher: AnyPublisher<Value, Never> {
    
    if let associated = objc_getAssociatedObject(self, &_didChangeAssociated) as? CurrentValueSubject<Value, Never> {
      return associated.eraseToAnyPublisher()
    } else {
      let associated = CurrentValueSubject<Value, Never>(value)
      objc_setAssociatedObject(self, &_didChangeAssociated, associated, .OBJC_ASSOCIATION_RETAIN)
      
      addDidUpdate { s in
        if Thread.isMainThread {
          associated.send(s)
        } else {
          DispatchQueue.main.async {
            associated.send(s)
          }
        }
      }
      
      return associated.eraseToAnyPublisher()
    }
  }
  
  public var didChangePublisher: AnyPublisher<Value, Never> {
    publisher.dropFirst().eraseToAnyPublisher()
  }
  
}

@available(iOS 13, macOS 10.15, *)
extension Publisher {
  
  public func removeDuplicates(_ computer: EqualityComputer<Output>) -> Publishers.Filter<Self> {
    filter {
      !computer.isEqual(value: $0)
    }
  }
  
}

extension Storage {
  
  @available(iOS 13, macOS 10.15, *)
  public func getter<Output>(
    filter: EqualityComputer<Value>,
    map: @escaping (Value) -> Output
  ) -> GetterSource<Value, Output> {
    
    let pipe = publisher
      .removeDuplicates(filter)
      .map(map)
        
    let getter = GetterSource<Value, Output>.init(input: pipe)
    
    return getter
    
  }
  
}

#endif
