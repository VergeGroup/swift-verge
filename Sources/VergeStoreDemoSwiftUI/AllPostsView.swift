
import SwiftUI
import VergeStore
import VergeCore

struct AllPostsView: View, Equatable {

  var session: Session

  private var posts: [Entity.Post] {
    session.store.primitiveState.db.entities.post.find(in: session.store.primitiveState.db.indexes.postIDs)
  }

  var body: some View {
    UseState(session.store) { _ in
      NavigationView {
        List {
          ForEach(self.posts.lazy.reversed()) { post in
            NavigationLink(destination: PostDetailView(session: self.session, post: post)) {
              PostView(session: self.session, post: post)
            }
          }
        }
        .navigationBarTitle("Posts")
      }
    }
  }

}
