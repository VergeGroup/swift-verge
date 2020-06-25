
import Foundation

import SwiftUI
import VergeStore

struct DualDisplayView: View {

  let session: Session

  @State private var selectedPost: Entity.Post?

  var body: some View {
    VStack {
      _AllPostsView(session: session, onSelect: { post in
        self.selectedPost = post
      })
      if selectedPost != nil {
        PostDetailView(session: session, post: selectedPost!)
      }
    }
  }

}

struct _AllPostsView: View {

  var session: Session
  var onSelect: (Entity.Post) -> Void

  private var posts: [Entity.Post] {
    session.store.state.db.entities.post.find(in: session.store.state.db.indexes.postIDs)
  }

  var body: some View {
    // TODO: filter
    UseState(session.store) { _ in
      NavigationView {
        List {
          ForEach(self.posts.lazy.reversed()) { post in
            Button(action: { self.onSelect(post)}) {
              PostView(session: self.session, post: post)
            }
          }
        }
        .navigationBarTitle("Posts")
      }
    }
  }

}
