import SwiftUI
import SpotifyService

struct HomeView: View {

  let stack: LoggedInStack

  var body: some View {
    NavigationView {
      VStack {
        NavigationLink("Settings", destination: SettingsView(stack: stack))
        Text("HomeView")
      }
    }
    .onAppear {
      self.stack.service.fetchTop()
    }
  }
}
