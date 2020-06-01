import SwiftUI
import SpotifyService

struct HomeView: View {

  let stack: LoggedInStack

  var body: some View {
    Text("HomeView")
      .onAppear {
        self.stack.service.fetchTop()
    }
  }
}
