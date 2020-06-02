import Foundation
import SwiftUI
import VergeStore

struct UserDetailView: View, Equatable {

  var session: Session

  let samples = [
    "cart",
    "manager",
    "illness",
    "agony",
    "ghostwriter",
    "lecture",
    "great",
    "exact",
    "ticket",
    "disappointment",
  ]

  let user: Entity.User

  private var posts: [Entity.Post] {

    session.store.primitiveState.db.entities.post.find(in:
      session.store.primitiveState.db.indexes.postIDsAuthorGrouped.orderedID(in: user.entityID)
    )
  }

  var body: some View {

    VStack {
      Text(user.name)
      Button(action: {
        self.session.sessionDispatcher.submitNewPost(title: self.samples.randomElement()!, from: self.user)
      }) {
        Text("Submit")
      }
      UseState(session.store) { (store) in
        List {
          ForEach(self.posts) { post in
            PostView(session: self.session, post: post)
          }
        }
      }
    }
  }
}
