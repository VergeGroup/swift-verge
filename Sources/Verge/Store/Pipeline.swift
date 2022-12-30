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

/**
 It produces outputs from inputs with their own conditions.
 
 Against just using map closure, it can drop output if there are no changes.
 This will be helpful in performance. Therefore most type parameters require Equatable.
 */
public enum Pipelines {
  
  /// KeyPath based pipeline, light weight operation just take value from source.
  public struct ChangesSelectPipeline<Source: Equatable, Output: Equatable>: PipelineType {
    
    public typealias Input = Changes<Source>
    
    public let keyPath: KeyPath<Input, Output>
    public let additionalDropCondition: ((Input) -> Bool)?
    
    public init(
      keyPath: KeyPath<Input, Output>,
      additionalDropCondition: ((Input) -> Bool)?
    ) {
      self.keyPath = keyPath
      self.additionalDropCondition = additionalDropCondition
    }
    
    public func yieldContinuously(_ input: Input) -> ContinuousResult<Output> {
      
      // TODO: Using keypath to look up modification
//      if let modification = input.modification {
//        switch modification {
//        case .indeterminate:
//          break
//        case .determinate(_, let changesKeyPaths):
//          
//          if changesKeyPaths.contains(keyPath) == false {
//            return .noUpdates
//          }
//          
//        }
//      }
            
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
    
    public func drop(while predicate: @escaping (Input) -> Bool) -> Self {
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
 
  /// Closure based pipeline, 
  public struct ChangesMapPipeline<Source: Equatable, Intermediate, Output: Equatable>: PipelineType {
    
    public typealias Input = Changes<Source>
    
    // MARK: - Properties
    
    public let intermediate: (Input) -> PipelineIntermediate<Intermediate>
    public let transform: (Intermediate) -> Output
    public let additionalDropCondition: ((Input) -> Bool)?
    
    public init(
      @PipelineIntermediateBuilder intermediate: @escaping (Input) -> PipelineIntermediate<Intermediate>,
      transform: @escaping (Intermediate) -> Output,
      additionalDropCondition: ((Input) -> Bool)?
    ) {
      self.intermediate = intermediate
      self.transform = transform
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
          
          let previousMapped = transform(previousIntermediate.value)
          let newMapped = transform(newIntermediate.value)
          
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
      transform(intermediate(input).value)
    }
      
    public func drop(while predicate: @escaping (Input) -> Bool) -> Self {
      return .init(
        intermediate: intermediate,
        transform: transform,
        additionalDropCondition: additionalDropCondition.map { currentCondition in
          { input in
            currentCondition(input) || predicate(input)
          }
        } ?? predicate
      )
    }
  }
  
  public struct BasicMapPipeline<Input: Equatable, Output: Equatable>: PipelineType {
        
    // MARK: - Properties
    
    public let map: (Input) -> Output
    public let additionalDropCondition: ((Input) -> Bool)?
    
    public init(
      map: @escaping (Input) -> Output,
      additionalDropCondition: ((Input) -> Bool)?
    ) {
      self.map = map
      self.additionalDropCondition = additionalDropCondition
    }
    
    // MARK: - Functions
    
    public func yieldContinuously(_ input: Input) -> ContinuousResult<Output> {
                      
      guard let additionalDropCondition = additionalDropCondition, additionalDropCondition(input) else {
        return .new(yield(input))
      }
      
      return .noUpdates
      
    }
    
    public func yield(_ input: Input) -> Output {
      map(input)
    }
    
    public func drop(while predicate: @escaping (Input) -> Bool) -> Self {
      return .init(
        map: map,
        additionalDropCondition: additionalDropCondition.map { currentCondition in
          { input in
            currentCondition(input) || predicate(input)
          }
        } ?? predicate
      )
    }
    
  }

}

extension PipelineType {

  /**
   For Changes input
   Produces output values using KeyPath-based projection.
   
   exactly same with ``PipelineType/select(_:)``
   */
  public static func map<Input, Output>(_ keyPath: KeyPath<Changes<Input>, Output>) -> Self
  where Input: Equatable, Output: Equatable, Self == Pipelines.ChangesSelectPipeline<Input, Output> {
    select(keyPath)
  }
  
  /**
   For Changes input
   Produces output values using KeyPath-based projection.
   
   exactly same with ``PipelineType/map(_:)-7xvom``
   */
  public static func select<Input, Output>(_ keyPath: KeyPath<Changes<Input>, Output>) -> Self
  where Input: Equatable, Output: Equatable, Self == Pipelines.ChangesSelectPipeline<Input, Output> {
    self.init(keyPath: keyPath, additionalDropCondition: nil)
  }
}

extension PipelineType {

  /**
   For Changes input
   Produces output values using closure-based projection.
   `map` closure takes the value projected from `using` closure which is intermediate value.
   If the intermediate value is not changed, map closure won't perform.
   
   - Parameters:
     - using: Specifies values for transforming. This function is annotated ``PipelineIntermediateBuilder``
     - transform: Transforms the given value from `using` function
   
   ```swift
   `.map(using: { $0.a; $0.b;}, transform: { a, b in ... }`
   ```
   
   */
  public static func map<Input, Intermediate, Output>(
    @PipelineIntermediateBuilder using intermediate: @escaping (Changes<Input>) -> PipelineIntermediate<Intermediate>,
    transform: @escaping (Intermediate) -> Output
  ) -> Self where Input: Equatable, Output: Equatable, Self == Pipelines.ChangesMapPipeline<Input, Intermediate, Output> {
    
    self.init(
      intermediate: intermediate,
      transform: transform,
      additionalDropCondition: nil
    )
  }
  
  /**
   For Changes input
   Produces output values using closure-based projection.
   Using Edge as intermediate, output value will be unwrapped value from the Edge.
   */
  public static func map<Input, EdgeIntermediate>(
    @PipelineIntermediateBuilder using intermediate: @escaping (Changes<Input>) -> PipelineIntermediate<Edge<EdgeIntermediate>>
  ) -> Self where Input: Equatable, Output: Equatable, Self == Pipelines.ChangesMapPipeline<Input, Edge<EdgeIntermediate>, EdgeIntermediate> {
    
    self.init(
      intermediate: intermediate,
      transform: { $0.wrappedValue },
      additionalDropCondition: nil
    )
  }
  
  /**
   For Changes input
   Produces output values using closure-based projection.
   
   ## 💡Tips
   Consider to use intermediate value with `using` parameter variant if `map` closure takes much higher cost.
   */
  public static func map<Input, Output>(
    _ transform: @escaping (Changes<Input>) -> Output
  ) -> Self where Input: Equatable, Output: Equatable, Self == Pipelines.ChangesMapPipeline<Input, Changes<Input>, Output> {
    
    self.init(
      intermediate: { $0 },
      transform: transform,
      additionalDropCondition: nil
    )
  }

}

public struct PipelineIntermediate<T>: Equatable {
  
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.comparer(lhs.value, rhs.value)
  }
      
  public var value: T
  public let comparer: ((T, T) -> Bool)
  
  @inlinable
  public init(value: T, comparer: @escaping (T, T) -> Bool) {
    self.value = value
    self.comparer = comparer
  }
    
  @inlinable
  public init(value: T) where T: Equatable {
    self.value = value
    self.comparer = (==) // this won't be called
  }
  
}

extension PipelineIntermediate where T : Equatable {
  
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.value == rhs.value
  }
  
}

/**
 A result-builder that builds ``PipelineIntermediate``.
 It converts tuple into ``PipelineIntermediate`` implementing Equatable.
 
 projects:
 ```
 {
   $0.a
   $0.b
 }
 
 // alternative syntax.
 { $0.a; $0.b; }
 ```

 into:
 ```
 PipelineIntermediate<(A, B)>
 ```
 */
@resultBuilder
public enum PipelineIntermediateBuilder {
  
  public static func buildBlock<IntermediateValue>(_ i: PipelineIntermediate<IntermediateValue>) -> PipelineIntermediate<IntermediateValue> {
    return i
  }
      
  public static func buildBlock<S1: Equatable>(_ s1: S1) -> PipelineIntermediate<S1> {
    .init(value: s1)
  }
  
  public static func buildBlock<S1: Equatable, S2: Equatable>(_ s1: S1, _ s2: S2) -> PipelineIntermediate<(S1, S2)> {
    .init(value: (s1, s2), comparer: ==)
  }
  
  public static func buildBlock<S1: Equatable, S2: Equatable, S3: Equatable>(_ s1: S1, _ s2: S2, _ s3: S3) -> PipelineIntermediate<(S1, S2, S3)> {
    .init(value: (s1, s2, s3), comparer: ==)
  }
  
  public static func buildBlock<S1: Equatable, S2: Equatable, S3: Equatable, S4: Equatable>(_ s1: S1, _ s2: S2, _ s3: S3, _ s4: S4) -> PipelineIntermediate<(S1, S2, S3, S4)> {
    .init(value: (s1, s2, s3, s4), comparer: ==)
  }
  
  public static func buildBlock<S1: Equatable, S2: Equatable, S3: Equatable, S4: Equatable, S5: Equatable>(_ s1: S1, _ s2: S2, _ s3: S3, _ s4: S4, _ s5: S5) -> PipelineIntermediate<(S1, S2, S3, S4, S5)> {
    .init(value: (s1, s2, s3, s4, s5), comparer: ==)
  }
  
  public static func buildBlock<S1: Equatable, S2: Equatable, S3: Equatable, S4: Equatable, S5: Equatable, S6: Equatable>(_ s1: S1, _ s2: S2, _ s3: S3, _ s4: S4, _ s5: S5, _ s6: S6) -> PipelineIntermediate<(S1, S2, S3, S4, S5, S6)> {
    .init(value: (s1, s2, s3, s4, s5, s6), comparer: ==)
  }
}
