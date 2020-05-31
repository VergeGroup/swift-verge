
import Foundation

import SpotifyService

struct LoggedOutView: View {

  let stack: LoggedOutStack
  @State private var isConnecting = false

  var body: some View {
    VStack {
      Text("Hello, World!")
      Button(action: {
        self.isConnecting = true
      }) {
        Text("Connect with Spotify")
      }
    }
    .sheet(isPresented: $isConnecting) {
      SafariView(url: Auth.authorization())
    }
  }
}
