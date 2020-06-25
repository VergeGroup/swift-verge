import Foundation
import SwiftUI
import VergeStore

struct PostView: View {

  var session: Session

  let post: Entity.Post

  private var user: Entity.User? {
    session.store.primitiveState.db.entities.user.find(by: post.userID)
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text(post.title)
      if user != nil {
        Text(user!.name)
      }
    }
  }
}

