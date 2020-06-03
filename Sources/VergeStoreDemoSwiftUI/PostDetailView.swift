import Foundation
import SwiftUI
import VergeStore

struct PostDetailView: View {

  let session: Session

  let post: Entity.Post

  private var comments: [Entity.Comment] {
    session.store.state.db.entities.comment.find(in: session.store.state.db.indexes.comments.orderedID(in: post.entityID))
  }

  var body: some View {
    VStack {
      Text("\(post.title)")
      Button(action: {
        self.session.sessionDispatcher.submitComment(body: "Hello", on: self.post.entityID)
      }) {
        Text("Add comment")
      }
      UseState(session.store) { _ in
        List(self.comments) { comment in
          commentView(comment: comment)
        }
      }
    }

  }
}

fileprivate func commentView(comment: Entity.Comment) -> some View {
  Text(comment.text)
    .padding(8)
}
