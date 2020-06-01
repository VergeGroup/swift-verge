
import Foundation

import SpotifyService
import VergeStore

struct LoggedOutView: View {

  let stack: LoggedOutStack
  @State private var isConnecting = false

  var body: some View {
    UseState(stack.derivedState) { derived in
      ProcessingOverlay(isProcessing: derived.value.isLoginProcessing) {
        VStack {
          Text("Hello, World!")
          Button(action: {
            self.isConnecting = true
          }) {
            Text("Connect with Spotify")
          }
        }
        .sheet(isPresented: self.$isConnecting) {
          SafariView(url: Auth.authorization())
        }
      }
    }
  }
}
