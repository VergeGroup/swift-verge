
import Foundation

import JAYSON
import VergeORM

extension Entities {

  public struct Playlist: EntityType {

    public typealias EntityIDRawType = String

    public var entityID: EntityID {
      .init(rawID)
    }

    public let rawID: String
    public let name: String
    public let images: [Image]
    public let owner: User.EntityID

    init(from json: JSON, context: DatabaseBatchUpdatesContext<Database>) throws {

      self.rawID = try json.next("id").getString()
      self.name = try json.next("name").getString()
      self.images = try json.next("images").getArray().map {
        try Image.init(from: $0)
      }

      let owner = try json.next("owner").get(Entities.User.init)
      context.user.insert(owner)

      self.owner = owner.entityID

    }
  }
}
