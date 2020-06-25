import Foundation

import JAYSON
import VergeORM

extension Entities {

  public struct Image: Equatable {

    public let width: Int?
    public let height: Int?
    public let url: URL

    init(from json: JSON) throws {

      self.width = json.width?.int
      self.height = json.height?.int
      self.url = try json.next("url").get {
        try URL(string: $0.getString()).unwrap()
      }
    }
  }

}
