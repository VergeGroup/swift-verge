import Foundation

import JAYSON
import VergeORM

extension Entities {

  public struct Me: EntityType, Equatable {

    public typealias EntityIDRawType = String

    public var entityID: EntityID {
      .init(rawID)
    }

    public let displayName: String
    public let rawID: String
    public let images: [Image]

    init(from json: JSON) throws {

      assert(json["type"]?.string == "user")

      self.displayName = try json.next("display_name").getString()
      self.rawID = try json.next("id").getString()
      self.images = try json.next("images").getArray().map { try Image(from: $0) }
    }

  }
}
