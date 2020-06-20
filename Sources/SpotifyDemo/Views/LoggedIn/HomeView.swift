import SwiftUI
import SpotifyService

struct HomeView: View {

  let stack: LoggedInStack

  var body: some View {
    NavigationView {
      VStack {
        NavigationLink("Settings", destination: SettingsView(stack: stack))
        Text("HomeView")
        Button(action: {
          _ = self.stack.logout()
        }) {
          Text("Logout")
        }
      }
    }
    .onAppear {
      self.stack.service.fetchTop()
    }
  }
}
