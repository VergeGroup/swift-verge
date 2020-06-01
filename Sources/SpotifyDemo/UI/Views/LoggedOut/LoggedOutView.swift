
import Foundation

import SpotifyService
import VergeStore
import SwiftUI

struct LoggedOutView: View {

  let stack: LoggedOutStack
  @State private var isConnecting = false

  var body: some View {
    UseState(stack.derivedState) { derived in
      ProcessingOverlay(isProcessing: derived.isLoginProcessing) {
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
