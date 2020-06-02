import Foundation
import SwiftUI
import VergeStore

struct PostDetailView: View {

  let session: Session

  let post: Entity.Post

  var body: some View {
    Text("\(post.title)")
  }
}
