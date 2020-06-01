import Foundation

import JAYSON
import VergeORM

extension Entities {

  public struct Image: Equatable {

    public let width: Int
    public let height: Int
    public let url: URL

    init(from json: JSON) throws {

      self.width = try json.next("width").getInt()
      self.height = try json.next("height").getInt()
      self.url = try json.next("url").get {
        try URL(string: $0.getString()).unwrap()
      }
    }
  }

}
