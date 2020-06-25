//
//  Util.swift
//  SpotifyService
//
//  Created by muukii on 2020/05/31.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

// MARK: - Optional
extension Optional {

//  public func filter(_ condition: (Wrapped) -> Bool) -> Wrapped? {
//    if let wrapped = self, condition(wrapped) {
//      return wrapped
//    }
//    return nil
//  }

  public func unwrap(orThrow error: Error) throws -> Wrapped {
    if let value = self {
      return value
    }
    throw error
  }

  public func unwrap(orThrow debugDescription: String? = nil, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) throws -> Wrapped {
    if let value = self {
      return value
    }
    throw Optional.UnwrappedNilError(
      debugDescription,
      file: file,
      function: function,
      line: line
    )
  }

  // MARK: - UnwrappedNilError
  public struct UnwrappedNilError: Swift.Error, CustomDebugStringConvertible {

    let file: StaticString
    let function: StaticString
    let line: UInt

    // MARK: Public
    public init(_ debugDescription: String? = nil, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {

      self.debugDescription = debugDescription ?? "<no description>"
      self.file = file
      self.function = function
      self.line = line
    }

    // MARK: CustomDebugStringConvertible
    public let debugDescription: String
  }
}

import Combine

extension Future {

  public static func success(_ output: Output) -> Self {
    Self.init { $0(.success(output)) }
  }

  public static func failure(_ error: Failure) -> Self {
    Self.init { $0(.failure(error)) }
  }
}
