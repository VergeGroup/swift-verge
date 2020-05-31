import SwiftUI
import SpotifyService

struct LoggedInView: View {

  let stack: LoggedInStack

  var body: some View {
    RootTabView()
      .onAppear {
        self.stack.service.fetchMe()
    }
  }
}
