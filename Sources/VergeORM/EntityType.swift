//
//  EntityType.swift
//  VergeORM
//
//  Created by muukii on 2019/12/13.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public protocol VergeTypedIdentifiable: Identifiable {
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

public protocol EntityType: VergeTypedIdentifiable {
  typealias Table = VergeORM.Table<Self, Read>
  // TODO: Add some methods for updating entity.
}

extension EntityType {
  public static func makeTable() -> Table {
    .init()
  }
}
