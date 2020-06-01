import SwiftUI
import SpotifyService

struct LoggedInView: View {

  let stack: LoggedInStack

  var body: some View {
    RootTabView(stack: stack)
      .onAppear {
        self.stack.service.fetchMe()
    }
  }
}
