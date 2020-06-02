
import Foundation
import VergeORM

enum Entity {
  struct Post: EntityType, Identifiable, Equatable {

    typealias EntityIDRawType = String
    var entityID: EntityID {
      .init(rawID)
    }
    let rawID: String
    var title: String
    var userID: User.EntityID
    var commentIDs: [Comment.EntityID] = []
    var likeCount: Int = 0
  }

  struct User: EntityType, Identifiable, Equatable {
    typealias EntityIDRawType = String
    var entityID: EntityID {
      .init(rawID)
    }
    let rawID: String
    var name: String
  }

  struct Comment: EntityType, Identifiable, Equatable {
    typealias EntityIDRawType = String
    var entityID: EntityID {
      .init(rawID)
    }
    let rawID: String
    var text: String
    var postID: Post.EntityID
  }
}
