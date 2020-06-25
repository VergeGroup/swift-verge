
import Foundation

import JAYSON
import VergeORM

extension Entities {

  public struct Artist: EntityType {

    public typealias EntityIDRawType = String

    public var entityID: EntityID {
      .init(rawID)
    }

    public let rawID: String
    public let images: [Image]
    public let name: String

    init(from json: JSON, context: DatabaseBatchUpdatesContext<Database>) throws {

      self.rawID = try json.next("id").getString()

      self.images = try json.next("images").getArray().map {
        try Image.init(from: $0)
      }

      self.name = try json.next("name").getString()



    }

  }

}

