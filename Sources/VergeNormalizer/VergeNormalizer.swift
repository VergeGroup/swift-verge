//
//  VergeNormalizer.swift
//  VergeStore
//
//  Created by muukii on 2019/12/07.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public protocol VergeTypedIdentifiable: Equatable, Identifiable {
  associatedtype RawValue: Hashable
  var rawID: RawValue { get }
}

extension VergeTypedIdentifiable {
  
  public var id: VergeTypedIdentifier<Self> {
    .init(raw: rawID)
  }
}

public struct VergeTypedIdentifier<T: VergeTypedIdentifiable> : Hashable {
  
  public let raw: T.RawValue
  
  public init(raw: T.RawValue) {
    self.raw = raw
  }
}

public protocol VergeNormalizedDatabase {
  
}

public final class VergeNormalizedDatabaseBatchContext {
  
}
