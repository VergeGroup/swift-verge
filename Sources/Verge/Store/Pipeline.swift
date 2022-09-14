//
// Copyright (c) 2020 Hiroshi Kimura(Muukii) <muukii.app@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

private let counter = VergeConcurrency.AtomicInt(initialValue: 0)

public enum ContinuousResult<Output> {
  case new(Output)
  case noUpdates
}

extension ContinuousResult: Equatable where Output: Equatable {
  
}

public protocol PipelineType<Input, Output> {
  
  associatedtype Input
  associatedtype Output
     
  func yield(_ input: Input) -> Output
   
  func yieldContinuously(_ input: Input) -> ContinuousResult<Output>
  
}

public protocol _PipelineType: PipelineType {
    
  var additionalDropCondition: (@Sendable (Input) -> Bool)? { get }
  
  func drop(while predicate: @escaping @Sendable (Input) -> Bool) -> Self
}

public protocol _SelectPipelineType: _PipelineType {
  
  var keyPath: KeyPath<Input, Output> { get }
  
  init(
    keyPath: KeyPath<Input, Output>,
    additionalDropCondition: (@Sendable (Input) -> Bool)?
  )
  
}

public protocol _MapPipelineType: _PipelineType {
  
  associatedtype Intermediate
  
  var intermediate: @Sendable (Input) -> Intermediate { get }
  var map: @Sendable (Intermediate) -> Output { get }
  
  init(
    intermediate: @escaping @Sendable (Input) -> Intermediate,
    map: @escaping @Sendable (Intermediate) -> Output,
    additionalDropCondition: (@Sendable (Input) -> Bool)?
  )
}

extension _SelectPipelineType {
  
  public func drop(while predicate: @escaping @Sendable (Input) -> Bool) -> Self {
    return .init(
      keyPath: keyPath,
      additionalDropCondition: additionalDropCondition.map { currentCondition in
        { input in
          currentCondition(input) || predicate(input)
        }
      } ?? predicate
    )
  }
  
}

extension _MapPipelineType {
  public func drop(while predicate: @escaping @Sendable (Input) -> Bool) -> Self {
    return .init(
      intermediate: intermediate,
      map: map,
      additionalDropCondition: additionalDropCondition.map { currentCondition in
        { input in
          currentCondition(input) || predicate(input)
        }
      } ?? predicate
    )
  }
  
}

public enum Pipelines {
   
  public struct SelectEquatableSourceEquatableOutputPipeline<Source: Equatable, Output: Equatable>: _SelectPipelineType {
    
    public typealias Input = Changes<Source>
    
    public let keyPath: KeyPath<Input, Output>
    public let additionalDropCondition: (@Sendable (Input) -> Bool)?
    
    public init(
      keyPath: KeyPath<Input, Output>,
      additionalDropCondition: (@Sendable (Input) -> Bool)?
    ) {
      self.keyPath = keyPath
      self.additionalDropCondition = additionalDropCondition
    }
    
    public func yieldContinuously(_ input: Input) -> ContinuousResult<Output> {
      
      guard let previous = input.previous else {
        return .new(input[keyPath: keyPath])
      }
      
      guard
        previous.primitive == input.primitive ||
          previous[keyPath: keyPath] == input[keyPath: keyPath]
      else {
        
        guard let additionalDropCondition = additionalDropCondition, additionalDropCondition(input) else {
          return .new(input[keyPath: keyPath])
        }
        
        return .noUpdates
      }
      
      return .noUpdates
      
    }
    
    public func yield(_ input: Input) -> Output {
      input[keyPath: keyPath]
    }
          
  }
 
  public struct MapEquatableSourceEquatableOutputPipeline<Source: Equatable, Intermediate: Equatable, Output: Equatable>: _MapPipelineType {
    
    public typealias Input = Changes<Source>
    
    // MARK: - Properties
    
    public let intermediate: @Sendable (Input) -> Intermediate
    public let map: @Sendable (Intermediate) -> Output
    public let additionalDropCondition: (@Sendable (Input) -> Bool)?
    
    public init(
      intermediate: @escaping @Sendable (Input) -> Intermediate,
      map: @escaping @Sendable (Intermediate) -> Output,
      additionalDropCondition: (@Sendable (Input) -> Bool)?
    ) {
      self.intermediate = intermediate
      self.map = map
      self.additionalDropCondition = additionalDropCondition
    }
    
    // MARK: - Functions
    
    public func yieldContinuously(_ input: Input) -> ContinuousResult<Output> {
      
      guard let previous = input.previous else {
        return .new(yield(input))
      }
      
      guard previous.primitive == input.primitive else {
        
        let previousIntermediate = intermediate(previous)
        let newIntermediate = intermediate(input)
        
        guard previousIntermediate == newIntermediate else {
          
          let previousMapped = map(previousIntermediate)
          let newMapped = map(newIntermediate)
          
          guard previousMapped == newMapped else {
            
            guard let additionalDropCondition = additionalDropCondition, additionalDropCondition(input) else {
              return .new(newMapped)
            }
            
            return .noUpdates
          }
                  
          return .noUpdates
        }
              
        return .noUpdates
        
      }
      
      return .noUpdates
    }
    
    public func yield(_ input: Input) -> Output {
      map(intermediate(input))
    }
      
  }

}


extension PipelineType {

  /**
   KeyPath
   - Input: ==
   - Output: ==
   
   exactly same with ``PipelineType/select(_:)``
   */
  public static func map<Input, Output>(_ keyPath: KeyPath<Changes<Input>, Output>) -> Self
  where Input: Equatable, Output: Equatable, Self == Pipelines.SelectEquatableSourceEquatableOutputPipeline<Input, Output> {
    select(keyPath)
  }
  
  /**
   KeyPath
   - Input: ==
   - Output: ==
   
   exactly same with ``PipelineType/map(_:)-7xvom``
   */
  public static func select<Input, Output>(_ keyPath: KeyPath<Changes<Input>, Output>) -> Self
  where Input: Equatable, Output: Equatable, Self == Pipelines.SelectEquatableSourceEquatableOutputPipeline<Input, Output> {
    self.init(keyPath: keyPath, additionalDropCondition: nil)
  }
}

extension PipelineType {

  /**
   Closure based map
   - Input: ==
   - Output: ==
   */
  public static func map<Input, Intermediate, Output>(
    _ intermediate: @escaping @Sendable (Changes<Input>) -> Intermediate,
    _ map: @escaping @Sendable (Intermediate) -> Output
  ) -> Self where Input: Equatable, Output: Equatable, Intermediate: Equatable, Self == Pipelines.MapEquatableSourceEquatableOutputPipeline<Input, Intermediate, Output> {
    
    self.init(
      intermediate: intermediate,
      map: map,
      additionalDropCondition: nil
    )
  }
  
  public static func map<Input, Output>(
    _ map: @escaping @Sendable (Changes<Input>) -> Output
  ) -> Self where Input: Equatable, Output: Equatable, Self == Pipelines.MapEquatableSourceEquatableOutputPipeline<Input, Changes<Input>, Output> {
    
    self.init(
      intermediate: { $0 },
      map: map,
      additionalDropCondition: nil
    )
  }

}
