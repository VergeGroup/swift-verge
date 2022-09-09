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

public protocol PipelineType {
  
  associatedtype Input
  associatedtype Output
     
  func yield(_ input: Input) -> Output
   
  func yieldContinuously(_ input: Input) -> ContinuousResult<Output>
  
  func drop(while predicate: @escaping @Sendable (Input) -> Bool) -> Self
}

public protocol _PipelineType: PipelineType {
    
  var additionalDropCondition: (@Sendable (Input) -> Bool)? { get }
}

public protocol _SelectPipelineType: _PipelineType {
  
  var keyPath: KeyPath<Input, Output> { get }
  
  init(
    keyPath: KeyPath<Input, Output>,
    additionalDropCondition: (@Sendable (Input) -> Bool)?
  )
  
}

public protocol _MapPipelineType: _PipelineType {
  
  var map: @Sendable (Input) -> Output { get }
  
  init(
    map: @escaping @Sendable (Input) -> Output,
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
    
  public struct SelectPipeline<Source, Output>: _SelectPipelineType {
    
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
    
    @_effects(readnone)
    public func yieldContinuously(_ input: Input) -> ContinuousResult<Output> {
      
      guard let _ = input.previous else {
        return .new(input[keyPath: keyPath])
      }
            
      guard let additionalDropCondition = additionalDropCondition, additionalDropCondition(input) else {
        return .new(input[keyPath: keyPath])
      }
            
      return .noUpdates
      
    }
    
    @_effects(readnone)
    public func yield(_ input: Input) -> Output {
      input[keyPath: keyPath]
    }
     
  }
    
  public struct SelectEquatableOutputPipeline<Source, Output: Equatable>: _SelectPipelineType {
    
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
    
    @_effects(readnone)
    public func yieldContinuously(_ input: Input) -> ContinuousResult<Output> {
      
      guard let previous = input.previous else {
        return .new(input[keyPath: keyPath])
      }
      
      guard
        previous[keyPath: keyPath] == input[keyPath: keyPath]
      else {
        
        guard let additionalDropCondition = additionalDropCondition, additionalDropCondition(input) else {
          return .new(input[keyPath: keyPath])
        }
        
        return .noUpdates
      }
      
      return .noUpdates
      
    }
    
    @_effects(readnone)
    public func yield(_ input: Input) -> Output {
      input[keyPath: keyPath]
    }
     
  }
    
  public struct SelectEquatableSourcePipeline<Source: Equatable, Output>: _SelectPipelineType {
    
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
    
    @_effects(readnone)
    public func yieldContinuously(_ input: Input) -> ContinuousResult<Output> {
      
      guard let previous = input.previous else {
        return .new(input[keyPath: keyPath])
      }
      
      guard
        previous.version == input.version ||
          previous.primitive == input.primitive
      else {
        
        guard let additionalDropCondition = additionalDropCondition, additionalDropCondition(input) else {
          return .new(input[keyPath: keyPath])
        }
        
        return .noUpdates
      }
      
      return .noUpdates
      
    }
    
    @_effects(readnone)
    public func yield(_ input: Input) -> Output {
      input[keyPath: keyPath]
    }
          
  }
  
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
    
    @_effects(readnone)
    public func yieldContinuously(_ input: Input) -> ContinuousResult<Output> {
      
      guard let previous = input.previous else {
        return .new(input[keyPath: keyPath])
      }
      
      guard
        previous.version == input.version ||
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
    
    @_effects(readnone)
    public func yield(_ input: Input) -> Output {
      input[keyPath: keyPath]
    }
          
  }
  
  public struct SelectEdgePipeline<Source, EdgeValue>: _SelectPipelineType {
    
    public typealias Input = Changes<Source>
    public typealias Output = Edge<EdgeValue>
    
    public let keyPath: KeyPath<Input, Output>
    public let additionalDropCondition: (@Sendable (Input) -> Bool)?
    
    public init(
      keyPath: KeyPath<Input, Output>,
      additionalDropCondition: (@Sendable (Input) -> Bool)?
    ) {
      self.keyPath = keyPath
      self.additionalDropCondition = additionalDropCondition
    }
    
    @_effects(readnone)
    public func yieldContinuously(_ input: Input) -> ContinuousResult<Output> {
      
      guard let previous = input.previous else {
        return .new(input[keyPath: keyPath])
      }
      
      guard
        previous.version == input.version ||
          previous[keyPath: keyPath].version == input[keyPath: keyPath].version
      else {
        
        guard let additionalDropCondition = additionalDropCondition, additionalDropCondition(input) else {
          return .new(input[keyPath: keyPath])
        }
        
        return .noUpdates
      }
      
      return .noUpdates
      
    }
    
    @_effects(readnone)
    public func yield(_ input: Input) -> Output {
      input[keyPath: keyPath]
    }
      
  }
  
  public struct SelectEdgeEquatableOutputPipeline<Source, EdgeValue: Equatable>: _SelectPipelineType {
    
    public typealias Input = Changes<Source>
    public typealias Output = Edge<EdgeValue>
    
    public let keyPath: KeyPath<Input, Output>
    public let additionalDropCondition: (@Sendable (Input) -> Bool)?
    
    public init(
      keyPath: KeyPath<Input, Output>,
      additionalDropCondition: (@Sendable (Input) -> Bool)?
    ) {
      self.keyPath = keyPath
      self.additionalDropCondition = additionalDropCondition
    }
    
    @_effects(readnone)
    public func yieldContinuously(_ input: Input) -> ContinuousResult<Output> {
      
      guard let previous = input.previous else {
        return .new(input[keyPath: keyPath])
      }
      
      guard
        previous.version == input.version ||
          previous[keyPath: keyPath].version == input[keyPath: keyPath].version ||
          previous[keyPath: keyPath].wrappedValue == input[keyPath: keyPath].wrappedValue
      else {
        
        guard let additionalDropCondition = additionalDropCondition, additionalDropCondition(input) else {
          return .new(input[keyPath: keyPath])
        }
        
        return .noUpdates
      }
      
      return .noUpdates
    }
    
    @_effects(readnone)
    public func yield(_ input: Input) -> Output {
      input[keyPath: keyPath]
    }
    
  }
    
  public struct SelectEdgeEquatableSourcePipeline<Source: Equatable, EdgeValue>: _SelectPipelineType {
    
    public typealias Input = Changes<Source>
    public typealias Output = Edge<EdgeValue>
    
    public let keyPath: KeyPath<Input, Output>
    public let additionalDropCondition: (@Sendable (Input) -> Bool)?
    
    public init(
      keyPath: KeyPath<Input, Output>,
      additionalDropCondition: (@Sendable (Input) -> Bool)?
    ) {
      self.keyPath = keyPath
      self.additionalDropCondition = additionalDropCondition
    }
    
    @_effects(readnone)
    public func yieldContinuously(_ input: Input) -> ContinuousResult<Output> {
      
      guard let previous = input.previous else {
        return .new(input[keyPath: keyPath])
      }
      
      guard
        previous.version == input.version ||
          previous.primitive == input.primitive ||
          previous[keyPath: keyPath].version == input[keyPath: keyPath].version
      else {
        
        guard let additionalDropCondition = additionalDropCondition, additionalDropCondition(input) else {
          return .new(input[keyPath: keyPath])
        }
        
        return .noUpdates
        
      }
      
      return .noUpdates
    }
    
    @_effects(readnone)
    public func yield(_ input: Input) -> Output {
      input[keyPath: keyPath]
    }
      
  }
  
  public struct SelectEdgeEquatableSourceEquatableOutputPipeline<Source: Equatable, EdgeValue: Equatable>: _SelectPipelineType {
    
    public typealias Input = Changes<Source>
    public typealias Output = Edge<EdgeValue>
    
    public let keyPath: KeyPath<Input, Output>
    public let additionalDropCondition: (@Sendable (Input) -> Bool)?
    
    public init(
      keyPath: KeyPath<Input, Output>,
      additionalDropCondition: (@Sendable (Input) -> Bool)?
    ) {
      self.keyPath = keyPath
      self.additionalDropCondition = additionalDropCondition
    }
    
    @_effects(readnone)
    public func yieldContinuously(_ input: Input) -> ContinuousResult<Output> {
      
      guard let previous = input.previous else {
        return .new(input[keyPath: keyPath])
      }
      
      guard
        previous.version == input.version ||
          previous.primitive == input.primitive ||
          previous[keyPath: keyPath].version == input[keyPath: keyPath].version ||
          previous[keyPath: keyPath].wrappedValue == input[keyPath: keyPath].wrappedValue
      else {
        
        guard let additionalDropCondition = additionalDropCondition, additionalDropCondition(input) else {
          return .new(input[keyPath: keyPath])
        }
        
        return .noUpdates
        
      }
      
      return .noUpdates
    }
    
    @_effects(readnone)
    public func yield(_ input: Input) -> Output {
      input[keyPath: keyPath]
    }
         
  }
  
  public struct MapPipeline<Source, Output>: _MapPipelineType {
    
    public typealias Input = Changes<Source>
    
    // MARK: - Properties
    
    public let map: @Sendable (Input) -> Output
    public let additionalDropCondition: (@Sendable (Input) -> Bool)?
    
    public init(
      map: @escaping @Sendable (Input) -> Output,
      additionalDropCondition: (@Sendable (Input) -> Bool)?
    ) {
      self.map = map
      self.additionalDropCondition = additionalDropCondition
    }
    
    // MARK: - Functions
    
    public func yieldContinuously(_ input: Input) -> ContinuousResult<Output> {
      
      guard let previous = input.previous else {
        return .new(map(input))
      }
      
      guard previous.version == input.version else {
        
        guard let additionalDropCondition = additionalDropCondition, additionalDropCondition(input) else {
          return .new(map(input))
        }
        
        return .noUpdates
      }
      
      return .noUpdates
    }
    
    public func yield(_ input: Input) -> Output {
      map(input)
    }
    
  
  }
  
  public struct MapEquatableOutputPipeline<Source, Output: Equatable>: _MapPipelineType {
    
    public typealias Input = Changes<Source>
    
    // MARK: - Properties
    
    public let map: @Sendable (Input) -> Output
    public let additionalDropCondition: (@Sendable (Input) -> Bool)?
    
    public init(
      map: @escaping @Sendable (Input) -> Output,
      additionalDropCondition: (@Sendable (Input) -> Bool)?
    ) {
      self.map = map
      self.additionalDropCondition = additionalDropCondition
    }
    
    // MARK: - Functions
    
    public func yieldContinuously(_ input: Input) -> ContinuousResult<Output> {
      
      guard let previous = input.previous else {
        return .new(map(input))
      }
      
      guard previous.version == input.version else {
        
        let mapped = map(input)
        
        guard map(previous) == mapped else {
          
          guard let additionalDropCondition = additionalDropCondition, additionalDropCondition(input) else {
            return .new(map(input))
          }
          
          return .noUpdates
        }
        
        return .noUpdates
      }
      
      return .noUpdates
    }
    
    public func yield(_ input: Input) -> Output {
      map(input)
    }
       
  }
  
  public struct MapEquatableSourcePipeline<Source: Equatable, Output>: _MapPipelineType {
    
    public typealias Input = Changes<Source>
    
    // MARK: - Properties
    
    public let map: @Sendable (Input) -> Output
    public let additionalDropCondition: (@Sendable (Input) -> Bool)?
    
    public init(
      map: @escaping @Sendable (Input) -> Output,
      additionalDropCondition: (@Sendable (Input) -> Bool)?
    ) {
      self.map = map
      self.additionalDropCondition = additionalDropCondition
    }
    
    // MARK: - Functions
    
    public func yieldContinuously(_ input: Input) -> ContinuousResult<Output> {
      
      guard let previous = input.previous else {
        return .new(map(input))
      }
      
      guard
        previous.version == input.version ||
          previous.primitive == input.primitive
      else {
        
        guard let additionalDropCondition = additionalDropCondition, additionalDropCondition(input) else {
          return .new(map(input))
        }
        
        return .noUpdates
      }
      
      return .noUpdates
    }
    
    public func yield(_ input: Input) -> Output {
      map(input)
    }
      
  }
  
  public struct MapEquatableSourceEquatableOutputPipeline<Source: Equatable, Output: Equatable>: _MapPipelineType {
    
    public typealias Input = Changes<Source>
    
    // MARK: - Properties
    
    public let map: @Sendable (Input) -> Output
    public let additionalDropCondition: (@Sendable (Input) -> Bool)?
    
    public init(
      map: @escaping @Sendable (Input) -> Output,
      additionalDropCondition: (@Sendable (Input) -> Bool)?
    ) {
      self.map = map
      self.additionalDropCondition = additionalDropCondition
    }
    
    // MARK: - Functions
    
    public func yieldContinuously(_ input: Input) -> ContinuousResult<Output> {
      
      guard let previous = input.previous else {
        return .new(map(input))
      }
      
      guard
        previous.version == input.version ||
          previous.primitive == input.primitive
      else {
        
        let mapped = map(input)
        
        guard map(previous) == mapped else {
          
          guard let additionalDropCondition = additionalDropCondition, additionalDropCondition(input) else {
            return .new(map(input))
          }
          
          return .noUpdates
        }
        
        return .noUpdates
        
      }
      
      return .noUpdates
    }
    
    public func yield(_ input: Input) -> Output {
      map(input)
    }
      
  }

}


extension PipelineType {
  
  /**
   KeyPath
   - Input: *
   - Output: *
   */
  @_disfavoredOverload // next to Edge
  public static func map<Input, Output>(_ keyPath: KeyPath<Changes<Input>, Output>) -> Self where Self == Pipelines.SelectPipeline<Input, Output> {
    self.init(keyPath: keyPath, additionalDropCondition: nil)
  }

  /**
   KeyPath
   - Input: *
   - Output: ==
   */
  @_disfavoredOverload // next to Edge
  public static func map<Input, Output>(_ keyPath: KeyPath<Changes<Input>, Output>) -> Self
  where Output: Equatable, Self == Pipelines.SelectEquatableOutputPipeline<Input, Output> {
    self.init(keyPath: keyPath, additionalDropCondition: nil)
  }

  /**
   KeyPath
   - Input: ==
   - Output: *
   */
  @_disfavoredOverload // next to Edge
  public static func map<Input, Output>(_ keyPath: KeyPath<Changes<Input>, Output>) -> Self
  where Input: Equatable, Self == Pipelines.SelectEquatableSourcePipeline<Input, Output> {
    self.init(keyPath: keyPath, additionalDropCondition: nil)
  }

  /**
   KeyPath
   - Input: ==
   - Output: ==
   */
  @_disfavoredOverload // next to Edge
  public static func map<Input, Output>(_ keyPath: KeyPath<Changes<Input>, Output>) -> Self
  where Input: Equatable, Output: Equatable, Self == Pipelines.SelectEquatableSourceEquatableOutputPipeline<Input, Output> {
    self.init(keyPath: keyPath, additionalDropCondition: nil)
  }

  /**
   KeyPath to Edge
   - Input: *
   - Output: *
   */
  public static func map<Input, Output>(_ keyPath: KeyPath<Changes<Input>, Edge<Output>>) -> Self
  where Self == Pipelines.SelectEdgePipeline<Input, Output> {
    self.init(keyPath: keyPath, additionalDropCondition: nil)
  }

  /**
   KeyPath to Edge
   - Input: *
   - Output: ==
   */
  public static func map<Input, Output>(_ keyPath: KeyPath<Changes<Input>, Edge<Output>>) -> Self
  where Output: Equatable, Self == Pipelines.SelectEdgeEquatableOutputPipeline<Input, Output> {
    self.init(keyPath: keyPath, additionalDropCondition: nil)
  }

  /**
   KeyPath to Edge
   - Input: ==
   - Output: *
   */
  public static func map<Input, Output>(_ keyPath: KeyPath<Changes<Input>, Edge<Output>>) -> Self
  where Input: Equatable, Self == Pipelines.SelectEdgeEquatableSourcePipeline<Input, Output> {
    self.init(keyPath: keyPath, additionalDropCondition: nil)
  }

  /**
   KeyPath to Edge
   - Input: ==
   - Output: ==
   */
  public static func map<Input, Output>(_ keyPath: KeyPath<Changes<Input>, Edge<Output>>) -> Self
  where Input: Equatable, Output: Equatable, Self == Pipelines.SelectEdgeEquatableSourceEquatableOutputPipeline<Input, Output> {
    self.init(keyPath: keyPath, additionalDropCondition: nil)
  }
}

extension PipelineType {
  /**
   Closure based map
   - Input: *
   - Output: *
   */
  public static func map<Input, Output>(_ closure: @escaping @Sendable (Changes<Input>) -> Output) -> Self where Self == Pipelines.MapPipeline<Input, Output> {
    self.init(map: closure, additionalDropCondition: nil)
  }

  /**
   Closure based map
   - Input: *
   - Output: ==
   */
  public static func map<Input, Output>(_ closure: @escaping @Sendable (Changes<Input>) -> Output) -> Self where Output: Equatable, Self == Pipelines.MapEquatableOutputPipeline<Input, Output> {
    self.init(map: closure, additionalDropCondition: nil)
  }

  /**
   Closure based map
   - Input: ==
   - Output: *
   */
  public static func map<Input, Output>(_ closure: @escaping @Sendable (Changes<Input>) -> Output) -> Self where Input: Equatable, Self == Pipelines.MapEquatableSourcePipeline<Input, Output> {
    self.init(map: closure, additionalDropCondition: nil)
  }

  /**
   Closure based map
   - Input: ==
   - Output: ==
   */
  public static func map<Input, Output>(_ closure: @escaping @Sendable (Changes<Input>) -> Output) -> Self where Input: Equatable, Output: Equatable, Self == Pipelines.MapEquatableSourceEquatableOutputPipeline<Input, Output> {
    self.init(map: closure, additionalDropCondition: nil)
  }

}

/// A handler that how receives and provides value.
///
/// inputs value: Input -> Pipeline -> Pipeline.Result
/// inputs value initially: -> Pipeline -> Output
@available(*, deprecated, message: "No longer used in v9")
public struct Pipeline<Input, Output>: Equatable, Sendable {

  public static func == (lhs: Pipeline<Input, Output>, rhs: Pipeline<Input, Output>) -> Bool {
    lhs.identifier == rhs.identifier
  }

  public typealias ContinuousResult = Verge.ContinuousResult<Output>

  // MARK: - Properties

  /*
   Properties should be `let` because to avoid mutating value with using the same identifier under the manager does not know that.
   */

  private let _makeOutput: @Sendable (Input) -> Output
  private let _makeContinousOutput: @Sendable (Input) -> ContinuousResult
  private let _dropInput: @Sendable (Input) -> Bool

  /**
   An identifier to be used from Derived to use the same instance if Pipeline is same.
   */
  let identifier: Int = counter.getAndIncrement()

  // MARK: - Initializers

  @_disfavoredOverload
  public init(
    makeInitial: @escaping @Sendable (Input) -> Output,
    update: @escaping @Sendable (Input) -> ContinuousResult
  ) {

    self.init(makeOutput: makeInitial, dropInput: { _ in false }, makeContinuousOutput: update)
  }

  public init(
    map: @escaping @Sendable (Input) -> Output
  ) {
    self.init(dropInput: { _ in false }, map: map)
  }

  public init(
    dropInput: @escaping @Sendable (Input) -> Bool,
    map: @escaping @Sendable (Input) -> Output
  ) {

    self.init(
      makeOutput: map,
      dropInput: dropInput,
      makeContinuousOutput: { .new(map($0)) }
    )
  }

  /// The primitive initializer
  init(
    makeOutput: @escaping @Sendable (Input) -> Output,
    dropInput: @escaping @Sendable (Input) -> Bool,
    makeContinuousOutput: @escaping @Sendable (Input) -> ContinuousResult
  ) {

    self._makeOutput = makeOutput
    self._dropInput = dropInput
    self._makeContinousOutput = { input in
      guard !dropInput(input) else {
        return .noUpdates
      }
      return makeContinuousOutput(input)
    }
  }

  // MARK: - Functions

  // TODO: Rename `makeContinuousOutput`
  public func makeResult(_ source: Input) -> ContinuousResult {
    _makeContinousOutput(source)
  }

  // TODO: Rename `makeOutput`
  public func makeInitial(_ source: Input) -> Output {
    _makeOutput(source)
  }

  /// Tune memoization logic up.
  ///
  /// - Parameter predicate: Return true, the coming input would be dropped.
  /// - Returns:
  public func drop(
    while predicate: @escaping @Sendable (Input) -> Bool
  ) -> Self {
    Self.init(
      makeOutput: _makeOutput,
      dropInput: { [_dropInput] input in
        guard !_dropInput(input) else {
          return true
        }
        guard !predicate(input) else {
          return true
        }
        return false
      },
      makeContinuousOutput: _makeContinousOutput
    )
  }

}
